function radii = singleDendriteDiameter(neuron, locationA, locationB, varargin)
    % SINGLEDENDRITEDIAMETER
    %
    % Description:
    %   Diameter of annotations along a single branch
    %
    % Syntax:
    %   radii = singleDendriteDiameter(neuron, locationA, locationB)
    %   radii = singleDendriteDiameter(neuron, locationA, locationB, 'numBins', 20);
    %
	% Inputs:
	%	neuron 			StructureAPI object
	%	locationA 		Starting location ID
    %	locationB 		Stopping location ID
    % Optional key/value inputs:
    %   numBins         Number of bins for histograms (default = 10)
    %   binLocations    Specify a vector of exact bin locations
    %   excludeSoma     Exclude soma (see notes, default = false)
    %   plot            Plot the output (default = true)
    %
    % Outputs:
    %   radii           All annotation radii along branch
    %
    % Examples:
    %   % Calculate dendrite diameter stats and plot histogram
    %   c4781 = Neuron(4781, 't');
    %   radii = singleDendriteDiameter(c4781, 178736, 193790);
    %
    % Notes:
    %   Exclude soma removes any annotation within 20% of the largest
    %   single annotation associated with the neuron.
    %
    % Help:
    %   This function takes the same inputs as the tortuosity analysis. For 
    %   more examples, see the help and tutorials for tortuoisty
    %
    % See also:
    %   SBFSEM.ANALYSIS.DENDRITEDIAMETER, TORTUOSITY, TUTORIAL_TORTUOSITY
    %
    % History:
    %   2Mar2019 - SSP
    %   29May2019 - SSP - Added stats report to the command line
    %   22Jun2019 - SSP - Errors refer to location ID now, not node number
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
        'Input a StructureAPI object');
    if ~ismember(locationA, neuron.nodes.ID)
        error('SBFSEM:SINGLEDENDRITEDIAMETER',...
            'Location ID %u is not associated with c%u!',...
            locationA, neuron.ID);
    elseif ~ismember(locationB, neuron.nodes.ID)
        error('SBFSEM:SINGLEDENDRITEDIAMETER',...
            'Location ID %u is not associated with c%u!',...
            locationB, neuron.ID);
    end
    
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
        error('SBFSEM:SINGLEDENDRITEDIAMETER',...
            'Nodes %u and %u are not connected!', locationA, locationB);
    else
        fprintf('Analyzing a %u node path between %u and %u\n',...
            numel(nodePath), locationA, locationB);
    end
    
    % Get the radius of each node
    radii = zeros(numel(nodePath), 1);
    for i = 1:numel(nodePath)
        locationID = nodeIDs(nodePath(i));
        radii(i) = neuron.nodes{neuron.nodes.ID == locationID, 'Rum'};
    end

    if ip.Results.ExcludeSoma
        largestRadius = max(radii);
        fprintf('Excluding largest %u annotations as soma\n',... 
            nnz(radii(radii > 0.8*largestRadius)));
        radii(radii > 0.8*largestRadius) = [];
    end

    % Report the results
    fprintf('\tMean = %.3f\n', mean(radii));
    fprintf('\tMedian = %.3f\n', median(radii));
    fprintf('\tSD = %.3f\n', std(radii));
    fprintf('\tSEM = %.3f\n\n', sem(radii));
    
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
