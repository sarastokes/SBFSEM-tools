classdef SynapseOData < sbfsem.io.OData
    % SYNAPSEODATA
    %
    % Description:
    %   Handles OData queries for synapses (Viking's child structures)
    %
    % Constructor:
    %   obj = sbfsem.io.SynapseOData(parentID, source);
    %
    % Inputs:
    %   ID      Viking parent ID number
    %   Source  Volume name
    %
    % See also:
    %   SBFSEM.IO.ODATA, SBFSEM.IO.NEURONODATA, SBFSEM.IO.GEOMETRYODATA
    %
    % History:
    %   3Jan2018 - SSP - Moved from NeuronOData
    %   5Mar2018 - SSP - Updated for new JSON decoder
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private, GetAccess = public)
        parentID
        
        numChildren = 0;
        
        % These properties are set by fetchChildData() and queried by
        % getChildNodes, getChildEdges or getSynapses
        synapseData
        nodeData
        edgeData
    end
    
    properties (Access = private)
        childURL
    end
    
    methods
        function obj = SynapseOData(parentID, source)
            obj@sbfsem.io.OData(source);
            obj.parentID = parentID;
            
            obj.childURL = getODataURL(obj.parentID, obj.source, 'child');
        end
        
        function [synapses, nodes, edges] = pull(obj)
            % PULL  Collect all the data
            obj.fetchChildData(true);
            synapses = obj.synapseData;
            nodes = obj.getChildNodes();
            edges = obj.getChildEdges();
        end
        
        function synapses = getSynapses(obj)
            % GETSYNAPSES  Returns synapses, doesn't query nodes/edges
            
            % 1. Has data been queried?
            if isempty(obj.synapseData)
                obj.fetchChildData();
            end
            
            % 2. Did the query return anything?
            if isempty(obj.synapseData)
                synapses = [];
            else
                synapses = obj.synapseData;
            end
        end
        
        function childNodes = getChildNodes(obj)
            % GETCHILDNODES  Returns synapse nodes as table
            
            if isempty(obj.nodeData)
                obj.fetchChildData(true);
            end
            
            if isempty(obj.nodeData)
                % If still empty, the neuron has no child structures
                childNodes = [];
            else
                childNodes = array2table(obj.nodeData);
                childNodes.Properties.VariableNames = obj.getNodeHeaders();
            end
        end
        
        function childEdges = getChildEdges(obj)
            % GETCHILDEDGES  Returns synapse links as table
            
            if isempty(obj.edgeData)
                obj.fetchChildData(true);
            end
            
            if isempty(obj.edgeData)
                % If still empty, the neuron has 0-1 child structures
                childEdges = [];
            else
                childEdges = array2table(obj.edgeData);
                childEdges.Properties.VariableNames = obj.getEdgeHeaders();
            end
        end
    end
    
    methods (Access = private)
        function fetchChildData(obj, expandChild)
            % FETCHCHILDDATA  Returns child data
            importedData = readOData(obj.childURL);
            
            obj.numChildren = numel(importedData.value);
            fprintf('c%u has %u child structures\n',... 
                obj.parentID, obj.numChildren);

            if ~isempty(importedData.value)
                value = cat(1, importedData.value{:});
                if obj.numChildren == 1
                    value.Label = {'-'};
                end
                data = struct2table(value);
                data.Tags = obj.parseTags(data.Tags);
                
                if expandChild
                    fprintf('Fetching data for %u child structures\n',...
                        obj.numChildren);
                    % Process all child IDs
                    [obj.nodeData, obj.edgeData, nullIDs] = obj.expandChildData(data.ID);
                    % Mark empty synapses
                    if ~isempty(nullIDs)
                        data.Label(data.ID == nullIDs,:) = {'Null'};
                    end
                else
                    obj.nodeData = [];
                    obj.edgeData = [];
                end
                
                obj.synapseData = data;
            else
                obj.synapseData = [];
            end
        end
        
        function Locs = processChildLocation(obj, ID)
            % PROCESSCHILDLOCATION  Fetch synapse location with error check
            
            locationURL = getODataURL(ID, obj.source, 'location');
            importedData = readOData(locationURL);
            
            if ~isempty(importedData.value)
                value = cat(1, importedData.value{:});
                Locs = obj.processLocationData(value);
            else
                Locs = NaN;
                % This is important to track bc throws errors in VikingPlot
                fprintf('No locations for s%u\n', ID);
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
    end
    
    methods (Access = private)
        function setupSynapses(obj)
            % SETUPSYNAPSES  Parse into sbfsem-tools variables
            
            import sbfsem.core.StructureTypes;
            % Init temporary variables to track nodes per synapse structure
            numSynapseNodes = [];
            for i = 1:height(obj.synapses)
                % Find the nodes associated with the synapse
                row = find(obj.nodes.ParentID == obj.synapses.ID(i));
                numSynapseNodes = cat(1, numSynapseNodes, numel(row));
                % Mark unique synapses, these will be plotted
                if numel(row) > 1
                    % Get the median annotation (along the Z-axis)
                    % TODO: decide if this is best approach
                    ind = find(obj.nodes.Z(row,:) == floor(median(obj.nodes.Z(row,:))));
                    obj.nodes.Unique(row(ind), :) = 1; %#ok
                elseif numel(row) == 1
                    obj.nodes.Unique(row,:) = 1;
                end
            end
            obj.synapses.N = numSynapseNodes;
        end
        
        function setStructureType(obj)
            % SETSTRUCTURETYPES  Match to TypeID the Viking StructureType
            
            structures = sbfsem.core.VikingStructureTypes(obj.synapses.TypeID);
            % Match to local StructureType
            localNames = cell(numel(structures), 1);
            for i = 1:numel(structures)
                localNames{i,:} = sbfsem.core.StructureTypes.fromViking(...
                    structures(i), obj.synapses.Tag{i,:});
            end
            obj.synapses.LocalName = localNames;
            % Make sure synapses match the new naming conventions
            makeConsistent(obj);
        end
    end
    
    methods (Static = true)
        function y = parseTags(x)
            % PARSETAGS  Get rid of the HTML markup, keep the synapse names
            %
            % 1Oct2017 - SSP
            
            if ischar(x)
                x = {x};
            end
            validateattributes(x, {'cellstr', 'cell'},{});
            
            y = cell(0,1);
            
            for i = 1:size(x,1)
                if ~isempty(x{i}) && numel(x{i}) > 1 && ~strcmp(x{i}, '-')
                    tag = x{i};
                    str = [];
                    % Standard tags are inside quotes
                    ind = strfind(tag, '"');
                    if ~isempty(ind)
                        % Each column is a beginning and ending quote
                        ind = reshape(ind, 2, numel(ind)/2);
                        for j = 1:numel(ind)/2
                            % Get the string inside each set of quotes
                            str = [str, tag(ind(1,j)+1:ind(2,j)-1), ';']; %#ok<AGROW>
                        end
                        % Remove the last semicolon
                        str = str(1:end-1);
                    else
                        str = cell(1,1);
                    end
                else
                    str = cell(1,1);
                end
                y = cat(1, y, str);
            end
        end
    end
end