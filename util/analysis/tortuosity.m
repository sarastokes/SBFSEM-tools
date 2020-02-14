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
    % See also:
    %   TUTORIAL_TORTUOSITY, SBFSEM.CORE.STRUCTUREAPI/GETBRANCHNODES
    %
	% History:
	%	26Sept2018 - SSP
    %   13Feb2020 - SSP Edited for sbfsem.core.StructureAPI/getBranchNodes
	% ---------------------------------------------------------------------

	assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
		'Input a StructureAPI object');
	
	ip = inputParser();
	ip.CaseSensitive = false;
	addParameter(ip, 'Plot', false, @islogical);
	addParameter(ip, 'Dim', 2, @(x) ismember(x, [2, 3]));
	parse(ip, varargin{:});
	plotme = ip.Results.Plot;
	ndim = ip.Results.Dim;

    % Get the annotations in the branch and pull the radius
	branchNodes = neuron.getBranchNodes(locationA, locationB);
    xyz = branchNodes.XYZum;

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