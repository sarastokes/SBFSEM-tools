function xy = axonCheck(neuron, dims)
	% AXONCHECK  Quickly visualize neuron plot
	%
	%   13Aug2017 - SSP - created
    %   3Jan2017 - SSP - updated neuron methods
    % ---------------------------------------------------------------------
    
    if nargin < 2
        dims = 2;
    end

	xyz = neuron.getCellXYZ();
    soma = neuron.getSomaXYZ();
    figure(); hold on;
    if dims == 2
    	xy = plot(xyz(:,1), xyz(:,2), '.k');
        plot(soma(:,1), soma(:,2),... 
            'ob', 'MarkerFaceColor', 'b');
    else
        xy = plot3(xyz(:,1), xyz(:,2), xyz(:,3), '.k');
        plot3(soma(:,1), soma(:,2), soma(:,3),...
            'ob', 'MarkerFaceColor', 'b');
    end