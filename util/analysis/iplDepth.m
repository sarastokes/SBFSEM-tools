function [iplPercent, stats] = iplDepth(Neuron, INL, GCL)
	% IPLDEPTH
    %
    % Description:
    %   
	% 
	% History
	%	7Feb2018 - SSP
	% ------------------------------------------------

	assert(isa(Neuron, 'Neuron'), 'Input a Neuron object');

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

	iplPercent = (xyz(:,3) - vGCL)./((vINL - vGCL)+eps);
	iplPercent(isnan(iplPercent)) = [];
    disp('Mean +- SEM microns (n):');
	printStat(iplPercent');

	stats = struct();
	stats.median = median(iplPercent);
	stats.sem = sem(iplPercent);
	stats.avg = mean(iplPercent);
	stats.n = numel(iplPercent);
	fprintf('Median IPL Depth = %.3g\n', stats.median);

	figure();
	hist(iplPercent, 20);
	xlim([0 1]);
    title(sprintf('IPL depth estimates for c%u', Neuron.ID));
	ylabel('Number of annotations');
	xlabel('Percent IPL Depth');

	figure();
	hist(vINL-vGCL, 20); hold on;
	title(sprintf('Variability in total IPL depth for c%u', Neuron.ID));
	xlabel('IPL depth (microns)');
	ylabel('Number of annotations');