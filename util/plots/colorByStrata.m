function fh = colorByStrata(neuron, numDimensions)
	% COLORBYSTRATA
    %
    % Description:
    %   Plot annotations colored by stratification
    %
    % Syntax:
    %   fh = COLORBYSTRATA(neuron, numDimensions);
    %
	% Input:
	%	neuron object
	% Optional input:
	%   numDimensions 	plot dimensions (default = 2)
	%
    % Output:
    %   fh              figure handle
    %
    %----------------------------------------------------------------------
	
	assert(isa(neuron, 'NeuronAPI'), 'Input Neuron object');
	if nargin < 2
		numDimensions = 2;
	else
		assert(ismember(numDimensions, [2 3]),...
			'Set dimensions to 2 or 3');
	end

	xyz = neuron.getCellXYZ();
	z = xyz(:,3);
	ind = [round(min(z)), round(max(z))];

	co = pmkmp(ind(2)-ind(1) + 1, 'CubicL');
	fh = figure('Color', 'w',...
		'Name', 'Stratification Color Map');
	ax = axes('Parent', fh);
	hold(ax, 'on');

	if numDimensions == 2
		for i = 1:size(xyz, 1)
			colorIndex = round(xyz(i,3))-ind(1)+1;
			plot(xyz(i,1), xyz(i,2),...
				'Marker', '.',...
				'Color', co(colorIndex,:),...
				'MarkerSize', 5);
		end
	else
		for i = 1:size(xyz, 1)
			colorIndex = round(xyz(i,3)) - ind(1)+1;
			plot3(xyz(i,1), xyz(i, 2), xyz(i, 3),...
				'Marker', '.',...
				'MarkerSize', 5,...
				'Color', co(colorIndex,:));
		end
	end
