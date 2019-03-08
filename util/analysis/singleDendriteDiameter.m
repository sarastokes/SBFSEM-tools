function radii = singleDendriteDiameter(neuron, locationA, locationB, varargin)
    % SINGLEDENDRITEDIAMETER
    %
    % Description:
    %   Diameter of annotations along a single branch
    %
	% Inputs:
	%	neuron 			StructureAPI object
	%	locationA 		Starting location ID
    %	locationB 		Stopping location ID
    % Optional key/value inputs:
    %   numBins         Number of bins for histograms (default = 10)
    %   binLocations    Specify a vector of exact bin locations
    %
    % Outputs:
    % radii             All annotation radii along branch
    %
    % See also:
    %   SBFSEM.ANALYSIS.DENDRITEDIAMETER, TORTUOSITY, TUTORIAL_TORTUOSITY
    %
    % History:
    %   2Mar2019 - SSP
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
        'Input a StructureAPI object');
    
    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'Plot', true, @islogical);
    addParameter(ip, 'NumBins', 10, @isnumeric);
    addParameter(ip, 'BinLocations', [], @isvector);
    addParameter(ip, 'ExcludeSoma', false, @islogical);
    parse(ip, varargin{:});
    binLocations = ip.Results.BinLocations;
    numBins = ip.Results.NumBins;

    % Annotations as a digraph
    [G, nodeIDs] = graph(neuron, 'directed', false);

    % Convert from location ID to graph node ID
    nodeA = find(nodeIDs == locationA);
    nodeB = find(nodeIDs == locationB);

	% Get the path between the nodes
	nodePath = shortestpath(G, nodeA, nodeB);

	% Misconnected nodes are common, check for them
	if isempty(nodePath)
		error('Nodes %u and %u are not connected!', nodeA, nodeB);
	else
		fprintf('Analyzing a %u node path between %u and %u\n',...
			numel(nodePath), nodeA, nodeB);
    end
    
    % Get the radius of each node
    radii = zeros(numel(nodePath), 1);
    for i = 1:numel(nodePath)
        locationID = nodeIDs(nodePath(i));
        radii(i) = neuron.nodes{neuron.nodes.ID == locationID, 'Rum'};
    end

    if ip.Results.ExcludeSoma
        largestRadius = max(radii);
        fprintf('Excluding largest %u annotations\n',... 
            nnz(radii(radii > 0.8*largestRadius)));
        radii(radii > 0.8*largestRadius) = [];
    end

    if ip.Results.Plot
        ax = axes('Parent', figure('Renderer', 'painters'));
        hold(ax, 'on');
        if ~isempty(binLocations)
            [a, binEdges] = histcounts(radii, binLocations);
        elseif ~isempty(numBins)
            [a, binEdges] = histcounts(radii, numBins);
        else
            [a, binEdges] = histcounts(radii);
        end
        binCenters = binEdges(2:end) - diff(binEdges);
        % Plot as diameter, not radius
        plot(2*binCenters, a, '-ok', 'LineWidth', 1.2);
        grid(ax, 'on');
        set(ax, 'TitleFontWeight', 'normal');
        title(ax, sprintf('c%u', neuron.ID));
        ylabel(ax, 'Number of annotations');
        xlabel(ax, 'Dendrite diameter (um)');
        figPos(ax.Parent, 0.8, 0.8);
    end
