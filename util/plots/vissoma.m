function fh = vissoma(xyr, varargin)
	% VISSOMA
    %
    % Description:
    %   Plot soma using viscircles
	%
	% INPUT: 
	%		xyr 					[x, y, radius]
	%	OPTIONAL: 
	%		ax 						existing axesHandle
	%		co 						edgecolor
	%		lw 						linewidth
	% OUTPUT: 
	%		fh 			figureHandle
	%
	% 29Jul2017 - SSP - created
    % 22Jul2018 - SSP - updated to current Neuron functions
    % ---------------------------------------------------------------------



	ip = inputParser();
	ip.CaseSensitive = false;
	ip.addParameter('ax', [], @ishandle);
	ip.addParameter('Color', 'k', @(x) isnumeric(x) || ischar(x));
	ip.addParameter('LineWidth', 1, @isnumeric);
	ip.parse(varargin{:});
	ax = ip.Results.ax;

	if isa(xyr, 'sbfsem.core.NeuronAPI')
        neuron = xyr;
		xyz = neuron.getSomaXYZ();
		xyr = [xyz(1:2), neuron.getSomaSize];
	end

	if isempty(ax)
		fh = figure('Renderer', 'painters');
		ax = axes('Parent', fh);
	else
		fh = ax.Parent;
    end
    hold(ax, 'on');

	viscircles(ax, xyr(1:2), xyr(3),...
		'LineWidth', ip.Results.LineWidth,... 
		'EdgeColor', ip.Results.Color);

	hold on; axis equal;