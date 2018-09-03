classdef Neuron < NeuronAPI
% NEURON
%
% Description:
%   A Matlab representation of a neuron ('Structure') in Viking
%
% Constructor:
%   obj = Neuron(cellID, source, includeSynapses);
%       or
%   obj = Neuron({cellID, source, includeSynapses});
%
% Inputs:
%   cellID      Viking Structure ID (double)
%   source      Volume name or abbreviation (char)
% Optional input:
%   includeSynapses     Load synapses (logical, default = false)
%
% Methods:
%   For a complete list, see the docs or type 'methods('Neuron')'
%
% Methods moved to external functions:
%   util/analysis/addAnalysis.m
%   util/renders/getBoundingBox.m
%   util/analysis/getIE.m
%
% History:
%   14Jun2017 - SSP - Created
%   01Aug2017 - SSP - Switched createUi to separate NeuronApp class
%   25Aug2017 - SSP - Added analysis property & methods
%   2Oct2017  - SSP - Ready for OData-based import
%   12Nov2017 - SSP - In sync with OData changes
%   4Jan2018  - SSP - New OData classes, added render methods
%   16Feb2018 - SSP - Added the omittedIDs property, applied in obj.graph()
%   6Mar2018  - SSP - NeuronCache compatibility
%   19Jul2018 - SSP - Option to specify different XY transforms
% -------------------------------------------------------------------------

    properties (Transient = true, Hidden = true)
        ODataClient
        GeometryClient
        SynapseClient
        includeSynapses
    end

    methods
        function obj = Neuron(ID, source, includeSynapses, transform)
            % NEURON  Basic cell data model
            %
            % Required inputs:
            %   ID                  Cell ID number in Viking
            %   source              Volume ('i', 't', 'r')
            %   includeSynapses     Import synapses (default=false)
            %
            % Use:
            %   % Import c127 in NeitzInferiorMonkey
            %   c127 = Neuron(127, 'i');
            % -------------------------------------------------------------
            obj@NeuronAPI();

            % By default, synapses are not imported
            obj.includeSynapses = false;
            % Default transform is local sbfsem-tools XY offset
            obj.transform = sbfsem.core.Transforms.SBFSEMTools;

            % NeuronCache inputs a single cell, cmd line as 2-3 arguments
            if nargin == 1 && iscell(ID)
                source = ID{2};
                if numel(ID) > 2
                    validateattributes(ID{3}, {'logical'}, {});
                    obj.includeSynapses = ID{3};
                end
                ID = ID{1};
            elseif nargin == 3
                validateattributes(includeSynapses, {'logical'}, {});
                obj.includeSynapses = includeSynapses;
            elseif nargin == 4
                if isa(transform, 'sbfsem.core.Transforms')
                    obj.transform = transform;
                else
                    obj.transform = sbfsem.core.Transforms.fromStr(transform);
                end
            end

            validateattributes(ID, {'numeric'}, {'numel', 1});
            source = validateSource(source);
            obj.transform = validateTransform(obj.transform, source);
            obj.ID = ID;
            obj.source = source;
            fprintf('-----c%u-----\n', obj.ID);

            % XYZ volume dimensions in nm/pix, nm/pix, nm/sections
            obj.volumeScale = getODataScale(obj.source);

            % Instantiate OData clients
            obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);
            if obj.includeSynapses
                obj.SynapseClient = sbfsem.io.SynapseOData(obj.ID, obj.source);
            else
                obj.SynapseClient = [];
            end
            obj.GeometryClient = [];

            % Fetch neuron OData and parse
            obj.pull();

            % Track when the Neuron object was created
            obj.lastModified = datestr(now);
            fprintf('\n\n');
        end

        function getGeometries(obj)
            % GETGEOMETRIES  Import ClosedCurve-related OData
            if isempty(obj.GeometryClient)
                obj.GeometryClient = sbfsem.io.GeometryOData(obj.ID, obj.source);
            end
            obj.geometries = obj.GeometryClient.pull();
        end

        function getSynapses(obj)
            % GETSYNAPSES  Import child structures
            obj.includeSynapses = true;

            if isempty(obj.SynapseClient)
                obj.SynapseClient = sbfsem.io.SynapseOData(obj.ID, obj.source);
            end

            [obj.synapses, childNodes, childEdges] = obj.SynapseClient.pull();
            % Clear out any existing synapse nodes/edges
            obj.nodes(obj.nodes.ParentID ~= obj.ID,:) = [];
            obj.edges(obj.edges.ID ~= obj.ID,:) = [];
            % Merge with neuron nodes/edges
            obj.nodes = [obj.nodes; obj.setXYZum(childNodes)];
            obj.edges = [obj.edges; childEdges];

            obj.setupSynapses();
        end

        function update(obj)
            % UPDATE  Updates existing OData
            % If you haven't imported synapses the update will skip them
            fprintf('NEURON: Updating OData for c%u\n', obj.ID);
            obj.pull();
            obj.lastModified = datestr(now);
        end

        function save(obj)
            % SAVE  Save changes to neuron
            % ----------------------------------------------------------
            uisave(obj, sprintf('c%u', obj.ID));
            fprintf('Saved!\n');
        end

        function checkSynapses(obj)
            % SYNAPSECHECK  Try to import synapses, if missing

            if isempty(obj.synapses)
                obj.getSynapses();
            end
        end

        function checkGeometries(obj)
            % CHECKGEOMETRIES   Try to import geometries, if missing
            if isempty(obj.geometries)
                obj.getGeometries();
            end
        end
    end

    methods (Access = private)
        function pull(obj)
            % PULL  Fetch and parse neuron's OData

            % Get the relevant data with OData queries
            [obj.viking, obj.nodes, obj.edges] = obj.ODataClient.pull();
            % XY transform and then convert data to microns
            obj.nodes = obj.setXYZum(obj.nodes);
            
            if obj.includeSynapses
                [obj.synapses, childNodes, childEdges] = obj.SynapseClient.pull();
                obj.nodes = [obj.nodes; obj.setXYZum(childNodes)];
                obj.edges = [obj.edges; childEdges];
                obj.setupSynapses();
            end
            
            if nnz(obj.nodes.Geometry == 6)
                obj.getGeometries();
                fprintf('     %u closed curve geometries\n',...
                    height(obj.geometries));
            end
            
            
            % Search for omitted nodes by location ID and section number
            obj.omittedIDs = omitLocations(obj.ID, obj.source);
            omittedSections = omitSections(obj.source);
            if ~isempty(omittedSections)
                for i = 1:numel(omittedSections)
                    row = obj.nodes.Z == omittedSections(i);
                    obj.omittedIDs = [obj.omittedIDs; obj.nodes(row,:).ID];
                end
            end
        end

        function nodes = setXYZum(obj, nodes)
            % SETXYZUM  Convert Viking pixels to microns
            if nnz(nodes.X) + nnz(nodes.Y) > 2
                nodes = estimateSynapseXY(obj, nodes);
            end
            
            % Apply transforms to NeitzInferiorMonkey
            if obj.transform == sbfsem.core.Transforms.SBFSEMTools
                xyDir = [fileparts(mfilename('fullpath')), '\data'];
                xydata = dlmread([xyDir,...
                    '\XY_OFFSET_NEITZINFERIORMONKEY.txt']);
                volX = nodes.X + xydata(nodes.Z,2);
                volY = nodes.Y + xydata(nodes.Z,3);
            else
                volX = nodes.VolumeX;
                volY = nodes.VolumeY;
            end

            % Create an XYZ in microns column
            nodes.XYZum = zeros(height(nodes), 3);
            % TODO: There's an assumption about the units in here...
            nodes.XYZum = bsxfun(@times,...
                [volX, volY, nodes.Z],...
                (obj.volumeScale./1e3));
            % Create a column for radius in microns
            nodes.Rum = nodes.Radius * obj.volumeScale(1)./1000;
        end

        function setupSynapses(obj)
            % SETUPSYNAPSES
            % TODO: This should be done elsewhere

            import sbfsem.core.StructureTypes;
            % Create a new column for "unique" synapses
            % The purpose of this is having 1 marker per synapse structure
            obj.nodes.Unique = zeros(height(obj.nodes), 1);
            if ~isempty(obj.synapses)
                % Init temporary variables to track nodes per synapse structure
                numSynapseNodes = [];
                for i = 1:height(obj.synapses) % For each synapse structre
                    % Find the nodes associated with the synapse
                    row = find(obj.nodes.ParentID == obj.synapses.ID(i));
                    numSynapseNodes = cat(1, numSynapseNodes, numel(row));
                    % Mark unique synapses, these will be plotted
                    if numel(row) > 1
                        % Get the median annotation (along the Z-axis)
                        % TODO: decide if this is best
                        ind = find(obj.nodes.Z(row,:) == floor(median(obj.nodes.Z(row,:))));
                        obj.nodes.Unique(row(ind),:) = 1; %#ok
                    elseif numel(row) == 1
                        obj.nodes.Unique(row, :) = 1;
                    end
                end
                obj.synapses.N = numSynapseNodes;

                % Match the TypeID to the Viking StructureType
                structures = sbfsem.core.VikingStructureTypes(obj.synapses.TypeID);
                % Match to local StructureType
                localNames = cell(numel(structures),1);
                for i = 1:numel(structures)
                    localNames{i,:} = sbfsem.core.StructureTypes.fromViking(...
                        structures(i), obj.synapses.Tags{i,:});
                end
                obj.synapses.LocalName = vertcat(localNames{:});
                % Make sure synapses match the new naming conventions
                if ~strcmp(obj.source, 'RC1')
                    makeConsistent(obj);
                end
            end
        end
    end
end
