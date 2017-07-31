function fh = synplotXYZ(cellData, syns, axHandle)
	% create a 3d scatter plot of synapse types
	%
	% INPUT:
	%	cellData 	structure from parseCellData.m
	%	syns 		synapse types (1 = string, 2 = cellstr, 3 = 'all')
	% OPTIONAL:
	%	axHandle 	existing axis handle
	%
	% OUTPUT:
	% 	fh			figure handle (optional)
	%
	% 16Jun2017 - SSP - created

	sc = getStructureColors();

	nodeDir = getSynNodes(cellData, syns);

	if nargin < 3
	  fh = figure('Color', 'w');
	  axHandle = axes('Parent', fh);
	else
	  gca = axHandle;
	end


	if ischar(syns)
		vals = getDim(cellData, nodeDir, 'XYZ');

		plot3(vals(1,:), vals(2,:), vals(3,:),... 
			'Marker', 'o', 'MarkerSize', 10,...
			'Color', sc(syns), 'LineStyle', 'none',...
			'DisplayName', syns); hold on;
	else
		for ii = 1:length(syns)
			vals = getDim(cellData, nodeDir{ii}, 'XYZ');

			plot(axHandle, vals(1,:), vals(2,:), vals(3,:),... 
				'Marker','o', 'MarkerSize', 10,...
				'Color', sc(syns), 'LineStyle', 'none',...
				'DisplayName', syns{ii}); hold on;
		end
	end

	legend('-DynamicLegend');
	set(legend, 'FontSize', 10, 'EdgeColor', 'w');
	xlabel('x coordinates');
  	ylabel('y coordinates');
  	zlabel('z coordinates');
  	grid on;
  	fh = gcf;
  	tightfig(fh);
