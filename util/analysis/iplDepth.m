function [iplPercent, stats] = iplDepth(Neuron, varargin)
	% IPLDEPTH
    %
    % Description:
    %   Calculates IPL depth based on stratification of single neuron
    %   
    % Syntax:
    %   [iplPercent, stats] = iplDepth(Neuron, INL, GCL);
    %
    % Inputs:
    %   Neuron      Neuron object
    %   INL         INL-IPL Boundary object
    %   GCL         GCL-IPL Boundary object
    % Optional key/value inputs (default value):
    %   numBins         Number of bins for histograms (20)
    %   binLocations    Specify a vector of exact bin locations
    %   iplMargin       Area around IPL boundaries to include (0.2)
    %   omitOutliers    Omit annotations exceeding iplMargin (true)
    %   includeSoma     Include "soma" annotations (true)
    %   plot            Plot the output? (true)
    %   ax              Handle to existing axes (none, create new figure)
    %   color           Color for the stratification line ([0 0 0])
    %
    % Outputs:
    %   iplPercent  Percent IPL depth for each annotation
    %   stats       Structure containing bin centers, values and stats
    %
    % Examples:
    %   [iplPercent, stats] = iplDepth(c10747);
    %   iplPercent = iplDepth(c10747, 'BinLocations', 0:0.1:1);
	%
    % Notes:
    %   Soma is defined as annotations over 80% as large as the largest
    %   annotation (which is assumed to be part of the soma).
    %
	% History
	%	7Feb2018 - SSP
    %   19Feb2018 - SSP - Added numBins input
    %   22Oct2018 - SSP - Added boundary markers from cache
    %   8Nov2018 - SSP - Removed bar plot option
    %   18Nov2018 - SSP - Specify bins option
    %   7Mar2019 - SSP - Added bin locations and counts to stats output
	% ---------------------------------------------------------------------

	assert(isa(Neuron, 'sbfsem.core.StructureAPI'),...
		'Input a StructureAPI object');
    
    GCL = sbfsem.builtin.GCLBoundary(Neuron.source, true);
    INL = sbfsem.builtin.INLBoundary(Neuron.source, true);
    
    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'numBins', 20, @isnumeric);
    addParameter(ip, 'binLocations', [], @isvector);
    addParameter(ip, 'Color', 'k', @(x) isvector(x) || ischar(x));
    addParameter(ip, 'plotVariability', false, @islogical);
    addParameter(ip, 'includeSoma', true, @islogical);
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'iplMargin', 0.2, @isnumeric);
    addParameter(ip, 'omitOutliers', true, @islogical);
    addParameter(ip, 'Plot', true, @islogical);
    addParameter(ip, 'PlotAll', true, @islogical);
    parse(ip, varargin{:});
    
    numBins = ip.Results.numBins;
    includeSoma = ip.Results.includeSoma;
    ax = ip.Results.ax;
    omitOutliers = ip.Results.omitOutliers;
    lineColor = ip.Results.Color;
    binLocations = ip.Results.binLocations;
    iplMargin = ip.Results.iplMargin;
    
    fprintf('-- c%u --\n', Neuron.ID);

	nodes = Neuron.getCellNodes;
	% Soma is anything within 20% of the soma radius
    if ~includeSoma
        fprintf('Omitting soma nodes\n');
    	somaRadius = Neuron.getSomaSize(false);
        nodes(nodes.Rum > 0.8*somaRadius, :) = [];
    end

	xyz = nodes.XYZum;

	[X, Y] = meshgrid(GCL.newXPts, GCL.newYPts);
	vGCL = interp2(X, Y, GCL.interpolatedSurface,...
		xyz(:,1), xyz(:,2));

	[X, Y] = meshgrid(INL.newXPts, INL.newYPts);
	vINL = interp2(X, Y, INL.interpolatedSurface,...
		xyz(:,1), xyz(:,2));

	iplPercent = (xyz(:, 3) - vINL) ./ ((vGCL - vINL)+eps);
	iplPercent(isnan(iplPercent)) = [];
    
    if omitOutliers
        iplPercent(iplPercent > 1 + iplMargin) = [];
        iplPercent(iplPercent < - iplMargin) = [];
    end
    disp('Mean +- SEM microns (n):');
	printStat(iplPercent');

	stats = struct();
	stats.median = median(iplPercent);
	stats.sem = sem(iplPercent);
	stats.avg = mean(iplPercent);
	stats.n = numel(iplPercent);
	fprintf('Median IPL Depth = %.3g\n', stats.median);
    
    if isempty(binLocations)
        [a, b] = histcounts(iplPercent, numBins);
    else
        [a, b] = histcounts(iplPercent, binLocations);
    end
    
    % Save bin centers and values
    stats.bins = b(2:end) - (b(2)-b(1));
    stats.counts = a;
    
    % Calculate the mode
    [~, ind] = max(a); 
    binMode = b(ind)+b(2)-b(1);
    stats.mode = binMode;
    fprintf('Mode = %.3g (for %u bins)\n', binMode, numBins);
    
    if ~ip.Results.Plot
        return;
    end
    
    if isempty(ax)
        ax = axes('Parent', figure());
        	figPos(ax.Parent, 0.7, 0.65);
        grid(ax, 'on'); hold(ax, 'on');
    	ylabel(ax, 'Number of annotations');
        set(ax, 'XTick', 0:0.25:1, 'TickDir', 'out',... 
            'XTickLabel', {'INL', 'off', 'IPL', 'on', 'GCL'},...
            'TitleFontWeight', 'normal');
    end
    
    plot(ax, b(1:end-1)+(b(2)-b(1)), a,...
        'Color', lineColor, 'Marker', 'o',...
        'MarkerSize', 4.5, 'LineWidth', 1,...
        'Display', sprintf('c%u', Neuron.ID));

    if ip.Results.PlotAll
        plot(stats.median, 0.1*max(a), 'Marker', '^',...
            'LineWidth', 1,...
            'Color', hex2rgb('ff4040'),...
            'Tag', sprintf('Median %.3f', stats.median),...
            'Display', sprintf('Median %.3f', stats.median));
    
        plot(stats.avg, 0.1*max(a), 'Marker', '^',...
            'LineWidth', 1,...
            'Color', hex2rgb('334de6'),...
            'Tag', sprintf('Mean %.3f', stats.avg),...
            'Display', sprintf('Mean %.3f', stats.avg));

        plot(stats.avg, 0.1*max(a), 'Marker', '^',...
            'LineWidth', 1,...
            'Color', hex2rgb('00cc4d'),...
            'Tag', sprintf('Mode %.3f', stats.mode),...
            'Display', sprintf('Mode %.3f', stats.mode));
    end

    xlim(ax, [-0.25, 1.25]);
    grid(ax, 'on'); hold(ax, 'on');
    set(ax, 'XTick', 0:0.25:1, 'TickDir', 'out',... 
        'XTickLabel', {'INL', 'off', 'IPL', 'on', 'GCL'},...
        'TitleFontWeight', 'normal');
    
    title(ax, sprintf('c%u Stratification', Neuron.ID));
	ylabel(ax, 'Number of annotations');
    
    if ip.Results.plotVariability
    	figure();
        hist(vINL-vGCL, numBins); hold on;
        title(sprintf('Variability in total IPL depth for c%u', Neuron.ID));
        xlabel('IPL depth (microns)');
        ylabel('Number of annotations');
    end
    
    
    if isempty(findobj(ax, 'Tag', 'GCL'))
        y = get(ax, 'YLim');
        rectangle(ax, 'Position', [-0.25, 0, 0.25, y(2)+1],...
            'FaceColor', [0, 0, 0, 0.1], 'EdgeColor', 'none');
        rectangle(ax, 'Position', [1, 0, 0.25, y(2)+1],...
            'FaceColor', [0, 0, 0, 0.1], 'EdgeColor', 'none');
        set(ax, 'YLim', y);
    end
    if ip.Results.PlotAll
        l = legend();
        set(l, 'EdgeColor', 'none', 'FontSize', 10,...
            'Orientation', 'horizontal', 'Location', 'bestoutside',...
            'NumColumns', 2, 'Box', 'off');
        fprintf('\n');
    end