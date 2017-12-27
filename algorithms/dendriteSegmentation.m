function [segments, segmentTable] = dendriteSegmentation(neuron, visualize)
    % DENDRITESEGMENTATION  Split neuron into non-branching segments
    %
    % Inputs:
    %   neuron          Neuron object
    %   visualize       Plot segments (false)
    % Outputs:
    %   segments        Cell array of segments, each is a list of IDs
    %   segmentTable    Information on each segment
    %
    % 14Dec2017 - SSP - moved from sbfsem.render.Cylinder
    
    if nargin < 2
        visualize = false;
    end
    
    % Generate an undirected graph of dendritic annotations
    G = graph(neuron);
    nodeIDs = str2double(G.Nodes{:,:});
    
    % Run a depth-first search on the graph
    % T is a table of events: when each node is first and last encountered.
    % 'finishnode' will translate to the list of nodes in each segment. For
    % lack of a better method, I'm using 'discovernode' to separate the
    % 'finishnode' lists.
    T = dfsearch(G, 1,...
        {'discovernode', 'finishnode'},... 
        'Restart', true);
    % If two annotations aren't connected, the Restart=true option will 
    % keep the dfsearch from stopping. Track this and print the location
    % IDs to the command line so the user knows to fix it
    extraStartNodes = [];
    
    % Variable setup
    openSegment = false;
    segments = cell(0,1);
    nodeList = [];
    
    % Split the tree into segments of degree=2 nodes
    % What is this called? There must be a name and algorithm out there
    for i = 1:height(T)
        switch T(i,:).Event
            case 'discovernode'
                % If a segment is open, add it to master list and close
                if openSegment
                    segments = cat(1, segments, {nodeList});
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
                    extraStartNodes = cat(1, extraStartNodes, T(i,:).Node);
                end
        end
    end    
    % A segment should still be open, close it out
    if openSegment
        segments = cat(1, segments, {nodeList});
    end
    
    disp(['Found ' num2str(numel(segments)), ' segments']);
    
    % Connect each back to the parent node
    for i = 1:numel(segments)
        IDs = segments{i};
        if numel(IDs) == 1
            parentNode = G.neighbors(IDs);
        else
            lastNode = IDs(end);
            pentultNode = IDs(end-1);
            neighborNodes = G.neighbors(lastNode);
            parentNode = neighborNodes(neighborNodes ~= pentultNode);
        end
        if ~isempty(parentNode)
            % Convert back to ID and add to segment
            segments{i} = cat(1, IDs, parentNode);
        end
    end
    
    % Get location, radius and section number for each node
    locations = cell(0,1);
    radii = cell(0,1);
    sections = cell(0,1);
    for i = 1:numel(segments)
        IDs = segments{i};
        iXYZ = []; iR = []; iSection = [];
        for j = 1:numel(IDs)
            row = find(neuron.nodes.ID == nodeIDs(IDs(j)));
            iXYZ = cat(1, iXYZ, neuron.nodes{row, 'XYZum'});
            iR = cat(1, iR, neuron.nodes{row, 'Rum'});
            iSection = cat(1, iSection, neuron.nodes{row, 'Z'});
        end
        locations = cat(1, locations, iXYZ);
        radii = cat(1, radii, iR);
        sections = cat(1, sections, iSection);
    end
    
    segmentTable = table(segments, sections, locations, radii,...
        'VariableNames', {'ID','Z','XYZum','Rum'});

    % Put this into a separate routine soon
    if visualize
        fh = figure('Name', 'Dendrite Segmentation');
        ax = axes('Parent', fh);
        hold(ax, 'on');
        co = pmkmp(height(segmentTable), 'CubicL');
        for i = 1:height(segmentTable)
            xyz = cell2mat(segmentTable(i,:).XYZum);
            plot3(xyz(:,1), xyz(:,2), xyz(:,3),...
                'Color', co(i,:), 'LineWidth', 1);            
        end
        axis(ax, 'equal'); axis (ax, 'tight');
        view(ax, 3);
    end