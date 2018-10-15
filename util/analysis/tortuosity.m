function d = tortuosity(neuron, locationA, locationB, varargin)
	% TORTUOSITY2
	%
	% Description:
	%	Quantify a branch's deviation from a straight line
	%
	% Syntax:
	%	d = tortuosity(neuron, locationA, locationB);
    %   d = tortuosity(neuron, locationA, locationB, 'Plot', true);
    %   d = tortuosity(neuron, locationA, locationB, 'Dim', 3);
	%
	% Inputs:
	%	neuron 			StructureAPI object
	%	locationA 		Starting location ID
	%	locationB 		Stopping location ID
	% Optional key/value inputs:
	%	Plot 			Plot results (default = true)
	%	Dim 			Dimensions (default = 2)
	%
	% Outputs:
	%	d 			Tortuosity metric
	%
	% History:
	%	26Sept2018 - SSP
	% -----------------------------------------------------------------

	assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
		'Input a StructureAPI object');
	
	ip = inputParser();
	ip.CaseSensitive = false;
	addParameter(ip, 'Plot', false, @islogical);
	addParameter(ip, 'Dim', 2, @(x) ismember(x, [2, 3]));
	parse(ip, varargin{:});
	plotme = ip.Results.Plot;
	ndim = ip.Results.Dim;

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

	% Get the XYZ location for each node
	xyz = zeros(numel(nodePath), 3);
	for i = 1:numel(nodePath)
		locationID = nodeIDs(nodePath(i));
		xyz(i, :) = neuron.nodes{neuron.nodes.ID == locationID, 'XYZum'};
	end

	% The actual branch distance / start and end branch distance
	% Basically deviation from a straight line drawn between the starting
	% and ending nodes.
	if ndim == 2
		branchDist = @(a, b) sqrt((a(1)-b(1)).^2 + (a(2)-b(2)).^2);
		d = sum(euclideanDist3(xyz))/branchDist(xyz(1,:), xyz(end, :));
	else
		branchDist = @(a, b) sqrt((a(1)-b(1)).^2 + (a(2)-b(2)).^2 + (a(3)-b(3)).^2);
		d = sum(euclideanDist2(xyz))/branchDist(xyz(1,:), xyz(end, :));
	end
	fprintf('c%u - %uD tortuosity = %.3g\n', neuron.ID, ndim, d);
    
    
    % Plot if necessary
    if plotme
        ax = axes('Parent', figure('Renderer', 'painters'));
        hold(ax, 'on');
        plot3(xyz(:, 1), xyz(:, 2), xyz(:, 3), 'k', 'Marker', '.');
        plot3(xyz([1, end], 1), xyz([1, end], 2), xyz([1, end], 3),...
            'm', 'LineWidth', 1.5);
        set(gca, 'TitleFontWeight', 'normal');
        xlabel(ax, 'X'); ylabel(ax, 'Y'); 
        axis(ax, 'equal', 'tight');
        grid(ax, 'on');
        if ndim == 2
            title(ax, sprintf('c%u - %.3g', neuron.ID, d));
            view(ax, 0, 90);
        else
            title(ax, sprintf('c%u - %.3g', neuron.ID, d));
            zlabel(ax, 'Z');
            view(ax, 3);
        end
    end