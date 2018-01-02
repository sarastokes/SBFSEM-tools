classdef NeuronOData < sbfsem.io.OData
%
% Inputs: 
%   ID      Viking ID number
%   Source  Volume name
%
% Properties:
%   ID              Viking ID number
%   Source          Full volume name
%   numChildren     Number of synapse structures
% Private properties:
%   vikingData      Neuron structure data
%   nodeData        Annotation locations
%   linkData        Connections between nodes
%   childData       Synapse data
%   scaleData       Volume dimensions
%
% Methods:
%   s = getStructure()
%   t = getNodes(includeChildren)
%   t = getEdges(includeChildren)
%   s = getChildData(dataType)
%   [a,b,c,d,e] = toNeuron();
%
%   10Nov2017 - SSP
% ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
        numChildren = 0
    end
    
    properties (Access = private)
        vikingData
        nodeData
        edgeData
        childData = struct()
        volumeData
    end
    
    properties (Constant = true, Hidden = true)
        INCLUDESYNAPSES = false;
    end
    
    methods
        function obj = NeuronOData(ID, source)
            % ODATAINTERFACE  Serves as middleman b/w OData and Matlab
            %  
            % Inputs:
            %   ID          neuron structure ID (from Viking)
            %   source      volume name (abbreviations okay)
            % Use:
            %   % Create OData object (cell 127 from NeitzInferiorMonkey)
            %   o127 = OData(127, 'i');
            % 
            % The idea is that other objects use OData, not independent
            %
            % 10Nov2017 - SSP

            obj@sbfsem.io.OData(source);
            assert(isnumeric(ID), 'ID must be numeric');
            
            vikingData = readOData(getODataURL(ID, source, 'neuron'));
            
            if vikingData.TypeID ~= 1
                disp('OData class only accepts TypeID=Cell');
                return;
            else
                obj.vikingData = vikingData;
                obj.ID = ID;
                obj.source = source;
            end
            
            obj.childData.data = [];
            obj.childData.nodes = [];
            obj.childData.edges = [];
        end
        
        function viking = getStructure(obj)
            % GETSTRUCTURE  Returns neuron's viking data

            viking = obj.vikingData;
        end

        function nodes = getNodes(obj, includeChildren)
            % GETNODES  Returns nodes as table
            %
            % Inputs:
            %   includeChildren     [false]     include child nodes
            
            if nargin < 2
                includeChildren = obj.INCLUDESYNAPSES;
            end
            if isempty(obj.nodeData)
                obj.fetchNodes();
            end
            nodes = array2table(obj.nodeData);

            if includeChildren
                if ~isempty(obj.childData)
                    nodes = [nodes; array2table(obj.childData.nodes)];
                else
                    obj.fetchSynapses(true);
                end
            end
            nodes.Properties.VariableNames = obj.getNodeHeaders; 
        end

        function edges = getEdges(obj, includeChildren)
            % GETEDGES  Returns edges as table
            %
            % Inputs: 
            %   includeChildren     [false] include child edges

            if nargin < 2
                includeChildren = obj.INCLUDESYNAPSES;
            end
            if isempty(obj.edgeData)
                obj.fetchEdges();
                % If edgeData is still empty, single annotation structure
                if isempty(obj.edgeData)
                    disp('No edges found');
                    edges = [];
                    return;
                end
            end

            edges = array2table(obj.edgeData);

            if includeChildren
                edges = [edges; array2table(obj.childData.edges)];
            end
            edges.Properties.VariableNames = obj.getEdgeHeaders;
        end
        
        function ret = getChildData(obj, dataType)
            % GETCHILDDATA
            %   Inputs:
            %       dataType    default=all
            %                   'all','data','edges','nodes'
            %   Output:
            %       table if nodes/edges, struct if all/data
             
            if nargin < 2
                dataType = 'all';
            else
                dataType = validatestring(dataType,... 
                    {'edges', 'nodes', 'data', 'all'});
            end
            
            switch dataType
                case 'nodes'
                    ret = obj.getChildNodes();
                case 'edges'
                    ret = obj.getChildEdges();
                case 'data'
                    obj.fetchSynapses(false);
                    ret = obj.childData.data;
                case 'all'
            end
        end
        
        function [viking, nodes, edges, child] = toNeuron(obj)
            % TONEURON  Fetches data and formats in old neuron style

            viking = obj.vikingData;
            childNodes = obj.getChildNodes;
            if ~isempty(childNodes)
                nodes = [obj.getNodes(); childNodes];
            else
                nodes = obj.getNodes();
            end
            childEdges = obj.getChildEdges();
            if ~isempty(childEdges)
                edges = [obj.getEdges(); childEdges];
            else
                edges = obj.getEdges();
            end
            child = obj.getChildData('data');
        end
        
        function [viking, nodes, edges, child] = pull(obj)
            % PULL  Fetches all data (nodes, edges, child)

            viking = obj.vikingData;
            nodes = obj.getNodes();
            edges = obj.getEdges();
            child = obj.getChildData('all');
        end
        
        function update(obj)
            % UPDATE  Fetches all existing data

            if ~isempty(obj.nodeData)
                obj.fetchNodes();
            end

            if ~isempty(obj.edgeData)
                obj.fetchEdges();
            end
            
            if obj.numChildren ~= 0
                if numel(unique(obj.nodeData.ID)) > 1
                    obj.fetchSynapses(true);
                else
                    obj.fetchSynapses();
                end
            end
        end
    end
    
    % Main data control private methods
    methods (Access = private)
        function fetchNodes(obj)
            % GETNODES  Returns all neuron structure locations

            obj.nodeData = obj.fetchLocationData(obj.ID);
        end
        
        function fetchEdges(obj)
            % GETEDGES  Returns all intra neuron structure links

            obj.edgeData = obj.fetchLinkData(obj.ID);
        end
        
        function fetchSynapses(obj, expandSynapses)
            % GETSYNAPSES  Fetch children structures
            %
            % Inputs:
            %   expandSynapses      [true] fetch child nodes and edges too
            
            if nargin < 2
                expandSynapses = true;
            else
                assert(islogical(expandSynapses),...
                    'expandSynapses is a t/f variable');
            end
            
            obj.childData = obj.fetchChildData(expandSynapses);
        end
        
        function childNodes = getChildNodes(obj)
            % GETCHILDNODES  Returns synapse nodes as table

            if isempty(obj.childData.nodes)
                obj.fetchSynapses(true);
            end
            
            if isempty(obj.childData.nodes)
                childNodes = [];
            else
                childNodes = array2table(obj.childData.nodes);
                childNodes.Properties.VariableNames = obj.getNodeHeaders;
            end
        end
        
        function childEdges = getChildEdges(obj)
            % GETCHILDEDGES  Returns synapse links as table
            
            if isempty(obj.childData.edges)
                obj.fetchSynapses(true);
            end
            
            if isempty(obj.childData.edges)
                childEdges = [];
            else
                childEdges = array2table(obj.childData.edges);
                childEdges.Properties.VariableNames = obj.getEdgeHeaders;
            end
        end
    end

    % OData import and processing methods
    methods (Access = private)
        function childData = fetchChildData(obj, expandChild)
            % FETCHCHILDDATA  Returns child data

            childURL = getODataURL(obj.ID, obj.source, 'child');
            importedData = readOData(childURL);
            obj.numChildren = numel(importedData.value);
            fprintf('c%u has %u child structures\n',...
                obj.ID, obj.numChildren);

            if ~isempty(importedData.value)
                if obj.numChildren == 1
                    importedData.value.Label = {'-'};
                end
                data = struct2table(importedData.value);
                data.Tags = parseTags(data.Tags);
                if expandChild
                    fprintf('Fetching data for %u child structures\n',...
                        obj.numChildren);
                    % Process all child IDs
                    [locs, loclinks, nullIDs] = obj.expandChildData(data.ID);
                    % Mark the empty synapses
                    if ~isempty(nullIDs)
                        data.Label(data.ID == nullIDs,:) = {'Null'};
                    end
                else
                    locs = []; 
                    loclinks = [];
                end
                childData.data = data;
                childData.nodes = locs;
                childData.edges = loclinks;
            else
                childData.data = [];
                childData.nodes = [];
                childData.edges = [];             
            end
        end
        
        function [childLocs, childLinks, nullIDs] = expandChildData(obj, IDs)
            % EXPANDCHILDDATA  Returns nodes and edges for child structures
            
            nullIDs = []; % Tracks IDs without location data
            childLocs = []; 
            childLinks = [];
            for i = 1:numel(IDs)
                locs = obj.processChildLocation(IDs(i));
                if isnan(locs)
                    nullIDs = [nullIDs, IDs(i)]; %#ok
                else % If valid, add to child locations and fetch links
                    childLocs = cat(1, childLocs, locs);
                    links = obj.fetchLinkData(IDs(i));
                    if ~isempty(links)
                        childLinks = cat(1, childLinks, links);
                    end
                end
            end
        end
        
        function Locs = processChildLocation(obj, ID)
            % PROCESSCHILDLOCATION  Fetch synapse location with error check

            locationURL = getODataURL(ID, obj.source, 'location');
            importedData = readOData(locationURL);
            if ~isempty(importedData.value)
                Locs = obj.processLocationData(importedData.value);
            else
                Locs = NaN;
                % This is important to track bc throws errors in VikingPlot
                fprintf('No locations for s%u\n', ID);
            end
        end      
    end
end