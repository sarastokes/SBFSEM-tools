classdef Segment < handle
    % SEGMENT
    %
    % Constructor:
    %   obj = Segments(neuron, startNode)
    %
    % Notes:
    %   A class to better handle the increasingly diverse demands for the
    %   dendrite segmentation function. When trying to work through this
    %   function, it's important to realize that there are two ID systems
    %   for annotations in play: 1) the Viking location IDs and 2) the node
    %   IDs within the graph representation. I've tried to keep the two
    %   clear in the comments.
    %
    % See also:
    %   NEURON/GRAPH, MINMAXNODES, DFSEARCH
    %
    % History:
    %   9Jun2018 - SSP - wrote from dendriteSegmentation
    %   26Sept2018 - SSP - added public functions for node -> location ID
    %   2Dec2018 - SSP - made parseStartNode function static
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
        Graph
        segmentTable
        nodeIDs
        discoverIDs
        startNode
    end
    
    properties (Dependent = true, Hidden = true)
        segments
    end
    
    methods
        function obj = Segment(neuron, startNode)
            obj.ID = neuron.ID;
            
            % Create the graph
            [obj.Graph, obj.nodeIDs] = graph(neuron, 'directed', false);
            
            % Identify the starting node
            if nargin < 2 || isempty(startNode)
                startNode = minmaxNodes(neuron, 'min');
            end
            
            % Converts locationID into nodeID
            obj.startNode = obj.parseStartNode(startNode, obj.nodeIDs);
            
            % Segment
            obj.performSegmentation(neuron);
        end
        
        function segments = get.segments(obj)
            segments = obj.segmentTable.ID;
        end
        
        function nodeID = node2loc(obj, locationID)
            % NODE2LOC  Convert node ID in graph to location ID in Viking
            nodeID = find(obj.nodeIDs == locationID);
        end
        
        function locationID = loc2node(obj, nodeID)
            % LOC2NODE  Convert node ID in graph to location ID in Viking
            locationID = obj.nodeIDs(nodeID);
        end
        
        function ax = plot(obj, ax)
            % PLOT
            if nargin < 2
                ax = axes('Parent', figure('Name', 'Dendrite Segmentation'));
            end
            hold(ax, 'on');
            co = pmkmp(height(obj.segmentTable), 'CubicL');
            for i = 1:height(obj.segmentTable)
                xyz = cell2mat(obj.segmentTable(i,:).XYZum);
                plot3(xyz(:,1), xyz(:,2), xyz(:,3),...
                    'Color', co(rem(i, size(co, 1)+1),:), 'LineWidth', 1);            
            end
            axis(ax, 'equal', 'tight');
            grid(ax, 'on');
            view(ax, 3);
        end
    end
    
    methods (Access = private)
        function performSegmentation(obj, neuron)
            % Run a depth-first search on the graph. T is a table of
            % events: when each node is first and last encountered.
            % 'finishnode' will translate to the list of nodes in each
            % segment. For lack of a better method, I'm using
            % 'discovernode' to separate the 'finishnode' lists.
            T = dfsearch(obj.Graph, obj.startNode,...
                {'discovernode', 'finishnode'},... 
                'Restart', true);            
            
            % If two annotations aren't connected, the Restart=true option
            % will keep the dfsearch from stopping. Track this and print
            % the location IDs to the command line for the user to fix
            extraStartNodes = [];
    
            % Variable init
            openSegment = false;
            segmentList = cell(0,1);
            nodeList = [];   
            
            % Split the tree into segments of degree=2 nodes
            % What is this called? There must be a name and algorithm
            for i = 1:height(T)
                switch T(i,:).Event
                    case 'discovernode'
                        % If segment is open, add to master list then close
                        if openSegment
                            segmentList = cat(1, segmentList, {nodeList});
                            openSegment = false;
                        end
                    case 'finishnode'
                        if ~openSegment
                            openSegment = true;
                            nodeList = [];
                        end
                        nodeList = cat(1, nodeList, T{i,'Node'});
                    case 'startnode'
                        % Track additional startnodes
                        if T(i,:).Node ~= 1
                            extraStartNodes = cat(1, extraStartNodes,...
                                T(i,:).Node);
                        end
                end
            end

            % A segment should still be open, close it out
            if openSegment
                segmentList = cat(1, segmentList, {nodeList});
            end

            % Print status to command line
            disp(['Found ' num2str(numel(segmentList)), ' branches']);
            if ~isempty(extraStartNodes)
                fprintf('%u disconnected nodes:\n', numel(extraStartNodes));
                disp(extraStartNodes)
            end
            
            % Connect each back to the parent node
            for i = 1:numel(segmentList)
                IDs = segmentList{i};
                if numel(IDs) == 1
                    parentNode = obj.Graph.neighbors(IDs);
                else
                    lastNode = IDs(end);
                    pentultNode = IDs(end-1);
                    neighborNodes = obj.Graph.neighbors(lastNode);
                    parentNode = neighborNodes(neighborNodes ~= pentultNode);
                end
                if ~isempty(parentNode)
                    % Convert back to ID and add to segment
                    segmentList{i} = cat(1, IDs, parentNode);
                end
            end            
                
            % Get location, radius and section number for each node
            locations = cell(0,1);
            radii = cell(0,1);
            sections = cell(0,1);
            for i = 1:numel(segmentList)
                IDs = segmentList{i};
                iXYZ = []; iR = []; iSection = [];
                for j = 1:numel(IDs)
                    row = find(neuron.nodes.ID == obj.nodeIDs(IDs(j)));
                    iXYZ = cat(1, iXYZ, neuron.nodes{row, 'XYZum'});
                    iR = cat(1, iR, neuron.nodes{row, 'Rum'});
                    iSection = cat(1, iSection, neuron.nodes{row, 'Z'});
                end
                locations = cat(1, locations, iXYZ);
                radii = cat(1, radii, iR);
                sections = cat(1, sections, iSection);
            end
            
            % Compile all the data into a table.
            obj.segmentTable = table(...
                segmentList, sections, locations, radii,...
                'VariableNames', {'ID','Z','XYZum','Rum'});
            
            % The order of discovery ('discovernode') provides a list of 
            % nodes where the parent node ID is always before children IDs.
            T = T(T.Event == 'discovernode', :);
            obj.discoverIDs = T.Node;    
        end
    end
    
    methods (Static)
        function startNode = parseStartNode(startNode, nodeIDs)
            % PARSESTARTNODE  Convert location ID into node ID
            if ismember(startNode, nodeIDs) 
                % Find node ID for a location ID
                startNode = find(nodeIDs == startNode);
                fprintf('Location ID mapped to node %u\n', startNode);
            elseif startNode > numel(nodeIDs)    
                warning('Invalid StartNode, setting to nodeID = 1');
                startNode = 1;
            end
        end
    end
end