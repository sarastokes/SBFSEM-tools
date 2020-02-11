classdef Neuron < sbfsem.core.NeuronAPI
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
%   For a complete list, see the docs or type 'methods('Neuron')'.
%   or 'methods('sbfsem.core.NeuronAPI')'.
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
%   10Jan2020 - SSP - Links property to access getAllLinkedNeurons output
% -------------------------------------------------------------------------

    properties
        links
    end
    
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
            % Optional inputs:
            %   includeSynapses     Import synapses (default=false)
            %   transform           Which XY transform (default=Viking)
            %
            % Use:
            %   % Import c127 in NeitzInferiorMonkey
            %   c127 = Neuron(127, 'i');
            % -------------------------------------------------------------
            obj@sbfsem.core.NeuronAPI(ID, source);

            % By default, synapses are not imported
            if nargin < 3
                obj.includeSynapses = false;
            else
                assert(islogical(includeSynapses),...
                    'includeSynapses must be true or false');
                obj.includeSynapses = includeSynapses;
            end
            % Default transform is local sbfsem-tools XY offset
            if nargin < 4
                obj.transform = sbfsem.core.Transforms.Viking;
            elseif ischar(transform)
                obj.transform = sbfsem.core.Transforms.fromStr(transform);
            elseif isa(transform, 'sbfsem.core.Transforms')
                obj.transform = transform;
            end

            source = validateSource(source);
            obj.transform = validateTransform(obj.transform, source);
            fprintf('-----c%u-----\n', obj.ID);

            % Instantiate OData clients
            if obj.includeSynapses
                obj.SynapseClient = sbfsem.io.SynapseOData(obj.ID, obj.source);
            else
                obj.SynapseClient = [];
            end
            obj.GeometryClient = [];

            % Fetch neuron OData and parse
            obj.pull();

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

            % Run query for the child structure annotations
            [obj.synapses, childNodes, childEdges] = obj.SynapseClient.pull();
            % Clear out any existing synapse nodes/edges
            obj.nodes(obj.nodes.ParentID ~= obj.ID,:) = [];
            obj.edges(obj.edges.ID ~= obj.ID,:) = [];
            % Merge with neuron nodes/edges
            obj.nodes = [obj.nodes; obj.setXYZum(childNodes)];
            obj.edges = [obj.edges; childEdges];

            obj.setupSynapses();
        end

        function checkLinks(obj)
            % CHECKLINKS  Imports links if not present
            if isempty(obj.links)
                obj.getLinks();
            end
        end

        function getLinks(obj)
            % GETLINKS  Loads in linked neurons
            obj.checkSynapses();
            
            T = getAllLinkedNeurons(obj);
            if isempty(T)
                return;
            end
            obj.links = sortrows(T, 'NeuronID');
        end

        function update(obj)
            % UPDATE  Updates existing OData
            % If you haven't imported synapses the update will skip them
            fprintf('NEURON: Updating OData for c%u\n', obj.ID);
            obj.pull();
            obj.lastModified = datestr(now);
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
    
    methods (Access = protected)
        function pull(obj)
            pull@sbfsem.core.StructureAPI(obj)
            if obj.includeSynapses
                obj.getSynapses();
            end
            if ~isempty(obj.links)
                fprintf('\tUpdating links for c%u\n', obj.ID);
                obj.getLinks();
            end
        end
    end

    methods (Access = protected)
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
                if ~strcmp(obj.source, 'RC1') | ~strcmp(obj.source, 'RPC1') | ~strcmp(obj.source, 'RC2')
                    makeConsistent(obj);
                end
            end
        end
    end
end
