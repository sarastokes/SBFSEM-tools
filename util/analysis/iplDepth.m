function [iplPercent, stats] = iplDepth(Neuron, INL, GCL, numBins)
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
    % Optional inputs:
    %   numBins     Number of bins for histograms (default = 20)
    % Outputs:
    %   iplPercent  Percent IPL depth for each annotation
    %   stats       Structure containing mean, median, SEM, SD, N
	% 
	% History
	%	7Feb2018 - SSP
    %   19Feb2018 - SSP - Added numBins input
    %   22Oct2018 - SSP - Added boundary markers from cache
	% ---------------------------------------------------------------------

	assert(isa(Neuron, 'sbfsem.core.StructureAPI'),...
		'Input a StructureAPI object');
    if nargin < 4
        numBins = 20;
    end
    if nargin < 3
        GCL = sbfsem.builtin.GCLBoundary(Neuron.source, true);
        INL = sbfsem.builtin.INLBoundary(Neuron.source, true);
    end

	nodes = Neuron.getCellNodes;
	% Soma is anything within 20% of the soma radius
	somaRadius = Neuron.getSomaSize(false);
	nodes(nodes.Rum > 0.8*somaRadius, :) = [];
	xyz = nodes.XYZum;

	[X, Y] = meshgrid(GCL.newXPts, GCL.newYPts);
	vGCL = interp2(X, Y, GCL.interpolatedSurface,...
		xyz(:,1), xyz(:,2));

	[X, Y] = meshgrid(INL.newXPts, INL.newYPts);
	vINL = interp2(X, Y, INL.interpolatedSurface,...
		xyz(:,1), xyz(:,2));

	% iplPercent = (xyz(:,3) - vGCL)./((vINL - vGCL)+eps);
    iplPercent = (xyz(:, 3) - vINL) ./ ((vGCL - vINL)+eps);
	iplPercent(isnan(iplPercent)) = [];
    disp('Mean +- SEM microns (n):');
	printStat(iplPercent');

	stats = struct();
	stats.median = median(iplPercent);
	stats.sem = sem(iplPercent);
	stats.avg = mean(iplPercent);
	stats.n = numel(iplPercent);
	fprintf('Median IPL Depth = %.3g\n', stats.median);

	ax = axes('Parent', figure());
	hist(ax, iplPercent, numBins);

    x = get(ax, 'XLim');
    if x(1) > 0
        x(1) = 0;
    end
    if x(2) < 1
        x(2) = 1;
    end
    xlim(ax, x);
    
    title(ax, sprintf('IPL depth estimates for c%u', Neuron.ID));
	ylabel(ax, 'Number of annotations');
	xlabel(ax, 'Percent IPL Depth');

	figure();
	hist(vINL-vGCL, numBins); hold on;
	title(sprintf('Variability in total IPL depth for c%u', Neuron.ID));
	xlabel('IPL depth (microns)');
	ylabel('Number of annotations');