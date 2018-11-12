function ax = blankStrataPlot(upperBound)
	% BLANKSTRATAPLOT
	%
	% Description:
	%	A blank plot formatted for IPL stratification
	%
	% Inputs:
	%	upperBound 		Maximum number of annotations 
	% Outputs:
	%	 ax 			Axes handle for new plot
	%
	% History:
	%	8Nov2018 - SSP
	% --------------------------------------------------------------------

	if nargin < 1
		upperBound = 1000;
	end

	ax = axes('Parent', figure());
	figPos(ax.Parent, 0.7, 0.6);
	grid(ax, 'on'); hold(ax, 'on');

	ylabel(ax, 'Number of annotations');
    set(ax, 'XTick', 0:0.25:1, 'TickDir', 'out',... 
        'XTickLabel', {'INL', 'off', 'IPL', 'on', 'GCL'},...
        'TitleFontWeight', 'normal');

    rectangle(ax, 'Position', [-0.25, 0, 0.25, upperBound+1],...
        'FaceColor', [0, 0, 0, 0.1], 'EdgeColor', 'none',...
        'Tag', 'INL');
    rectangle(ax, 'Position', [1, 0, 0.25, upperBound+1],...
        'FaceColor', [0, 0, 0, 0.1], 'EdgeColor', 'none',...
        'Tag', 'GCL');

	xlim(ax, [-0.25, 1.25]);
	ylim(ax, [0, upperBound]);
