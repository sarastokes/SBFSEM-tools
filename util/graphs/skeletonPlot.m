function fh = skeletonPlot(cellData, whichDim, axHandle)
	% simple skeleton - only nodes, no edges
	%
	% INPUTS:
	%	cellData		structure from parseNodesEdges.m
	% 	whichDim		which dimensions to plot
	% OPTIONAL:
	%	axHandle		add to existing axis
	%
	% OUTPUTS:
	%	fh				figure handle
	%
	% 17Jun2017 - SSP - created

	if nargin < 3
		fh = figure('Color', 'w');
		axHandle = gca;
	end
	hold on;

	xyz = [];
	for ii = 1:length(cellData.skeleton)
		try
			xyz = [xyz; cellData.props.xyzMap(cellData.skeleton{1,ii})];
		end
	end

	if length(whichDim == 3)
		plot3(xyz(:,1), xyz(:,2), xyz(:,3), '.k',...
			'LineStyle', 'none',...
			'Parent', axHandle);
	else
		ind = find('XYZ', whichDim);
		plot(xyz(:, ind(1)), xyz(:, ind(2)), '.k',...
			'LineStyle', 'none',...
			'Parent', axHandle);
	end
	fh = gcf;
