classdef Neuron < handle
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
% -------------------------------------------------------------------------
    
    properties (SetAccess = private, GetAccess = public)
        % Cell ID in Viking
        ID
        % Volume cell exists in
        source 
        % Neuron's data from Viking
        viking
        % Table of each location ID
        nodes
        % Table of the links between annotations
        edges
        % Volume dimensions (nm per pixel)
        volumeScale
        % Attributes of each synapse
        synapses
        % Closed curve geometries
        geometries
        % Date info pulled from odata             
        lastModified 
        % Analyses related to the neuron
        analysis = containers.Map();
        % Render of neuron
        model = [];
        % Omitted location IDs
        omittedIDs = [];
    end
    
    properties (Transient = true, Hidden = true)
        ODataClient
        GeometryClient
        SynapseClient
        includeSynapses
    end
    
    properties (Dependent = true, Transient = true, Hidden = true)
        somaRow     % Largest "cell" node's row
        offEdges    % Unfinished branches
    end
    
    properties (Constant = true, Transient = true, Hidden = true)
        USETRANSFORM = true;
    end

    methods
        function obj = Neuron(ID, source, includeSynapses)
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

            % By default, synapses are not imported
            obj.includeSynapses = false;
            
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
            end
            
            validateattributes(ID, {'numeric'}, {'numel', 1});
            source = validateSource(source);
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

            % Search for omitted location IDs
            obj.omittedIDs = omitLocations(obj.ID, obj.source);

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

        function model = build(obj, renderType, varargin)
            % BUILD  Quick access to render methods
            % 
            % Inputs:
            %   renderType      'cylinder' (default), 'closedcurve', 'disc'
            %   varargin        Input to render function
            % Output:
            %   model           render object (also stored in properties)
            %--------------------------------------------------------------
            if nargin < 2
                renderType = 'cylinder';
            end
            
            if ~isempty(obj.model)
                obj.model = [];
            end
            
            switch lower(renderType)
                case {'cylinder', 'cyl'}
                    model = sbfsem.render.Cylinder(obj, varargin{:});
                case {'closedcurve', 'cc', 'curve'}
                    model = renderClosedCurve(obj, varargin{:});
                case {'outline'}
                    model = sbfsem.builtin.ClosedCurve(obj);
                case 'disc'
                    model = sbfsem.render.Disc(obj, varargin{:});
                otherwise
                    warning('Render type %s not found', renderType);
                    return;
            end
            obj.model = model;
        end

        function dae(obj, fName)
            % DAE  Export model as COLLADA file
            %
            % Inputs:
            %   fName       filename (char)
            %
            % See also: 
            %   EXPORTSCENEDAE
            % -------------------------------------------------------------
            if isempty(obj.model)
                obj.build();
            elseif isnumeric(obj.model) || isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                warning('Model must be a Cylinder render, use exportSceneDAE');
                return;
            end

            if nargin < 2
                obj.model.dae();
            else
                obj.model.dae(fName);
            end
        end

        function render(obj, varargin)
            % RENDER
            %
            % Inputs:
            %   varargin        See render function inputs
            % 
            % See also:
            %   RENDERCLOSEDCURVE, SBFSEM.RENDER.CYLINDER
            % -------------------------------------------------------------
            
            if ~isempty(obj.model)
                if isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                    obj.model.trace(varargin{:});
                elseif isnumeric(obj.model) % Closed curve volume
                    volumeRender(obj.model,...
                        'Tag', ['c', num2str(obj.ID)],...
                        varargin{:});
                else
                    obj.model.render(varargin{:});
                    view(3);
                end
            else
                warning('No model - use BUILD function first');
            end
        end
        
        function somaRow = get.somaRow(obj)
            % This is the row associated with the largest annotation
            somaRow = find(obj.nodes.Radius == max(obj.nodes.Radius));
        end
        
        function offEdges = get.offEdges(obj)
            rows = obj.nodes.OffEdge == 1;
            offEdges = obj.nodes(rows,:).ID;
        end

        function synapseNames = synapseNames(obj, toChar)
            % SYNAPSENAMES  Returns a list of synapse types
            %
            % Input:
            %   toChar          Convert to char (default = false)
            %
            % Output: 
            %   synapseNames    Array of sbfsem.core.StructureTypes
            %                   Or cell of strings, if toChar = true
            % -------------------------------------------------------------
            
            if nargin < 2
                toChar = false;
            end
            
            obj.checkSynapses();
            
            synapseNames = unique(obj.synapses.LocalName);
            if toChar
                synapseNames = vertcat(arrayfun(@(x) char(x),...
                    synapseNames, 'UniformOutput', false));
            end
        end

        function synapseNodes = getSynapseNodes(obj, onlyUnique)
            % GETSYNAPSENODES  Returns a table of only synapse annotations
            % Inputs:
            %   onlyUnique      t/f  return only unique locations
            % -------------------------------------------------------------
            obj.checkSynapses();
            if nargin < 2
                onlyUnique = true;
            end
            if onlyUnique
                row = obj.nodes.ParentID ~= obj.ID & obj.nodes.Unique;
            else
                row = obj.nodes.ParentID ~= obj.ID;
            end
            synapseNodes = obj.nodes(row, :);

            % Sort by parentID
            synapseNodes = sortrows(synapseNodes, 'ParentID');
            synapseTable = sortrows(obj.synapses, 'ParentID');
            synapseNodes = [synapseNodes, synapseTable(:, {'N', 'LocalName'})];
        end

        function cellNodes = getCellNodes(obj)
            % GETCELLNODES  Return only cell body nodes

            row = obj.nodes.ParentID == obj.ID;
            cellNodes = obj.nodes(row, :);
        end
        
        function IDs = synapseIDs(obj, whichSyn)
            % SYNAPSEIDS  Return parent IDs for synapses
            %
            % Input:
            %   whichSyn        synapse name (default = all)
            % -------------------------------------------------------------
            
            obj.checkSynapses();
            
            if nargin < 2
                IDs = obj.synapses.ID;
            else % Return a single synapse type
                if ischar(whichSyn)
                    whichSyn = sbfsem.core.StructureTypes(whichSyn);
                end
                row = obj.synapses.LocalName == whichSyn;
                IDs = obj.synapses(row,:).ID;
            end
        end

        function xyz = getCellXYZ(obj, useMicrons)
            % GETCELLXYZ  Returns cell body coordinates
            %
            %   Inputs:     useMicrons  [t]  units = microns or volume
            % ----------------------------------------------------------
            if nargin < 2
                useMicrons = true;
            end
            
            row = obj.nodes.ParentID == obj.ID;
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y','Z'}};
            end
        end

        function um = getSomaSize(obj, useDiameter)
            % GETSOMASIZE  Returns soma radius in microns
            %
            % Optional inputs:
            %   useDiameter   Return diameter not radius (false)
            % ----------------------------------------------------------
            if nargin < 2
                useDiameter = false;
                disp('Returning radius');
            end

            if useDiameter
                um = max(obj.nodes.Rum) * 2;
                if nargout == 0
                    fprintf('c%u soma diameter = %.3f um\n', obj.ID, um);
                end
            else
                um = max(obj.nodes.Rum);
                if nargout == 0
                    fprintf('c%u soma radius = %.3f um\n', obj.ID, um);
                end
            end
        end

        function n = getSynapseN(obj, synapseName)
            % GETSYNAPSEN
            % Input:
            %   synapseName     Name of synapse to count
            % ----------------------------------------------------------
            obj.checkSynapses();
            if ischar(synapseName)
                synapseName = sbfsem.core.StructureTypes(synapseName);
            end
            n = nnz(obj.synapses.LocalName == synapseName);
        end
        
        function xyz = getSynapseXYZ(obj, syn, useMicrons)
            % GETSYNAPSEXYZ  Get xyz of synapse type
            %
            % Inputs:   
            %   syn             Synapse name
            %   useMicrons      Logical (default = true)
            % -------------------------------------------------------------
            if nargin < 3
                useMicrons = true;
            end
            obj.checkSynapses();
            
            % Find the synapse structures matching synapse name
            if ischar(syn)
                syn = sbfsem.core.StructureTypes(syn);
            end
            
            row = obj.synapses.LocalName == syn;                           
            IDs = obj.synapses.ID(row,:);
            % Find the unique instances of each synapse ID
            row = ismember(obj.nodes.ParentID, IDs) & obj.nodes.Unique;

            % Get the xyz values for only those rows
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.dataTable{row, {'X', 'Y', 'Z'}};
            end
        end 
        
        function id = getSomaID(obj, toClipboard)
            % GETSOMAID  Get location ID for current "soma" node
            % 
            % Optional input:
            %   toClipboard     Copy to clipboard (default = false)
            % ----------------------------------------------------------
            
            if nargin < 2
                toClipboard = false;
            end
            
            id = obj.nodes{obj.somaRow, 'ID'};
            % In case more than one node has maximum size
            id = id(1);

            if toClipboard
                clipboard('copy', id);
            end
        end

        function xyz = getSomaXYZ(obj, useMicrons)
            % GETSOMAXYZ  Coordinates of soma
            %
            % Optional input:
            %   useMicrons      logical, default = true
            % ----------------------------------------------------------

            if nargin < 2 % default unit is microns
                useMicrons = true;
            end

            % get the XYZ values
            if useMicrons
                xyz = obj.nodes{obj.somaRow, 'XYZum'};
            else
                xyz = obj.nodes{obj.somaRow, {'X', 'Y', 'Z'}};
            end

            if size(xyz, 1) > 1
                xyz = xyz(1,:);
            end
        end
        
        function xyz = getDAspect(obj, ax)
            % GETDASPECT  
            %   Scales a plot by x,y,z dimensions
            % Optional inputs:
            %   ax      axesHandle to apply daspect
            % ----------------------------------------------------------            
            % xyz = obj.volumeScale/max(abs(obj.volumeScale));  
            xyz = max(obj.volumeScale)./obj.volumeScale;
            if nargin == 2
                assert(isa(ax, 'matlab.graphics.axis.Axes'),...
                    'Input an axes handle');
                daspect(ax, xyz);
            end
        end

        function [G, nodeIDs] = graph(obj, varargin)
            % NEURON2GRAPH  Create a graph representation
            %
            % Optional key/value inputs:
            %   directed        [f]     directed or undirected
            %   synapses        [f]     include child structures
            %   visualize       [f]     plot the graph?
            %
            % Outputs:
            %   G               graph or digraph
            %   nodesIDs        array (ith entry is loc ID of node i)
            % -------------------------------------------------------------
            
            ip = inputParser();
            addParameter(ip, 'directed', false, @islogical);
            addParameter(ip, 'synapses', false, @islogical);
            addParameter(ip, 'visualize', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.synapses
                edge_rows = obj.edges;
            else
                edge_rows = obj.edges.ID == obj.ID;
            end

            if ip.Results.directed
                G = digraph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(deblank(num2str(obj.edges.B(edge_rows,:)))));
            else
                G = graph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(num2str(obj.edges.B(edge_rows,:))));
            end

            if ip.Results.visualize
                figure();
                plot(G);
            end
            
            % Lookup table for locationIDs of nodes where ith entry is
            % the location ID of node i.
            nodeIDs = str2double(G.Nodes{:,:});

            % Remove any omitted nodes from the graph
            if ~isempty(obj.omittedIDs)
                for i = 1:numel(obj.omittedIDs)
                    G = G.rmnode(find(nodeIDs == (obj.omittedIDs(i))'));
                    nodeIDs = str2double(G.Nodes{:,:});
                end
                fprintf('Omitted %u locations\n', numel(obj.omittedIDs));
            end
        end

        function save(obj)
            % SAVE  Save changes to neuron
            % ----------------------------------------------------------
            uisave(obj, sprintf('c%u', obj.ID));
            fprintf('Saved!\n');
        end
                 
        function printSyn(obj)
            % PRINTSYN  Print synapse summary to the command line
            
            obj.checkSynapses();
            % Viking synapse names first
            [a, b] = findgroups(obj.synapses.TypeID);
            b2 = sbfsem.core.VikingStructureTypes(b);
            x = splitapply(@numel, obj.synapses.TypeID, a);
            fprintf('\n-------------------\nc%u synapses:', obj.ID);
            fprintf('\n-------------------\nViking synapse names:\n');
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b2(ii));
            end
            % Then detailed SBFSEM-tools names
            fprintf('\n-------------------\nDetailed names:\n');
            synapseNames = obj.synapseNames;
            for i = 1:numel(synapseNames)
                fprintf('%u %s\n',...
                    size(obj.getSynapseXYZ(synapseNames(i)), 1),...
                    char(synapseNames(i)));
            end
            fprintf('\n-------------------\n');
        end
               
        function checkSynapses(obj)
            % SYNAPSECHECK  If no synapses, import them
            
            if isempty(obj.synapses)
                obj.getSynapses();
            end
        end
    end

    methods (Access = private)
        function pull(obj)
            % PULL  Fetch and parse neuron's OData

            % Get the relevant data with OData queries
            [obj.viking, obj.nodes, obj.edges] = obj.ODataClient.pull();
            if obj.includeSynapses
                [obj.synapses, childNodes, childEdges] = obj.SynapseClient.pull();
                obj.nodes = [obj.nodes; childNodes];
                obj.edges = [obj.edges; childEdges];
                obj.setupSynapses();
            end

            % XY transform and then convert data to microns
            obj.nodes = obj.setXYZum(obj.nodes);
            
            if nnz(obj.nodes.Geometry == 6)
                obj.getGeometries();
                fprintf('     %u closed curve geometries\n',... 
                    height(obj.geometries));
            end
        end        
        
        function nodes = setXYZum(obj, nodes)
            % SETXYZUM  Convert Viking pixels to microns
            
            volX = nodes.VolumeX;
            volY = nodes.VolumeY;            
            % Apply transforms to NeitzInferiorMonkey            
            if strcmp(obj.source, 'NeitzInferiorMonkey') && obj.USETRANSFORM
                xyDir = [fileparts(mfilename('fullpath')), '\data'];
                xydata = dlmread([xyDir,...
                    '\XY_OFFSET_NEITZINFERIORMONKEY.txt']);
                volX = nodes.VolumeX + xydata(nodes.Z,2);
                volY = nodes.VolumeY + xydata(nodes.Z,3);                           
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
