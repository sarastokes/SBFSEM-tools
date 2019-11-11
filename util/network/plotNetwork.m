function p = plotNetwork(G, varargin)
	% PLOTNETWORK
    %
    % Inputs:
    %   G           Directed graph from addToNetwork
    % Optional key/value inputs:
    %   cmap        User-defined colormap
    %   useSoma     Center nodes at soma location (default = false)
    %   weighted  Set linewidth to strength (default = false)
    %   layout      graph/plot layout (default = auto)
    %
    % See also:
    %   GRAPH/PLOT, ADDTONETWORK
    %
    % History:
	%   1Oct2018 - SSP
    % ---------------------------------------------------------------------

	ip = inputParser();
	ip.CaseSensitive = false;
	addParameter(ip, 'cmap', []);
	addParameter(ip, 'useSoma', false, @islogical);
    addParameter(ip, 'weighted', false, @islogical);
    addParameter(ip, 'Layout', 'auto', @ischar);
	parse(ip, varargin{:});

	useSoma = ip.Results.useSoma;
	if ~ismember('X', G.Nodes.Properties.VariableNames)
		useSoma = false;
	end
	weighted = ip.Results.weighted;
	if ~ismember('Weight', G.Edges.Properties.VariableNames)
		weighted = false;
	end

	if isempty(ip.Results.cmap)
		n = numel(unique(G.Nodes.NodeColors));
		cmap = pmkmp(n+1, 'cubicyf');
		cmap(end,:) = [];
	else
		cmap = ip.Results.cmap;
	end

	ax = axes('Parent', figure('Renderer', 'painters'));
	p = G.plot('Layout', ip.Results.Layout);
	p.MarkerSize = 6;
	p.NodeCData = G.Nodes.NodeColors;
	if useSoma
		p.XData = G.Nodes.X;
		p.YData = G.Nodes.Y;
	end

	if weighted
		p.LineWidth = G.Edges.Weight;
	end

	figPos(gcf, 0.7, 0.7);
	axis(ax, 'tight', 'off');
	colormap(cmap);