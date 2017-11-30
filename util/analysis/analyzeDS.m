function d = analyzeDS(neuron, varargin)
	% ANALYZEDS - analyze dendrite size
	% INPUTS:
	%		neuron 				neuron object
	%	OPTIONAL:
	%		dim 		[2]			2 or 3 dimensions
	%		ind 		[]			rows to remove (axon, soma)
	%		nbins 	[auto]	number of bins for histogram
	%		graph 	[true]	whether to plot results
	%		search 	[2 5]		primary dendrite search window
	%	OUTPUT:
	%		d 			structure containing stats
	%
	%	NOTES: search window will depend on bin count,
	%		which should typically be high (20 usually works)
	%		bin 1 is omitted assuming it's mostly the soma.
	%		Keep an eye on the search window printout which
	%		will show the how consistent the analysis is.
	%
	% 13Aug2017 - SSP - created
	% 25Aug2017 - SSP - now called from PrimaryDendriteDiameter

	ip = inputParser();
	ip.addParameter('dim', 2, @(x) ismember(x, [2 3]));
	ip.addParameter('ind', [], @isvector);
	ip.addParameter('nbins', [], @isnumeric);
	ip.addParameter('graph', false, @islogical);
	ip.addParameter('search', [2 5], @isvector);
	ip.parse(varargin{:});
	dim = ip.Results.dim;
	ind = ip.Results.ind;
	nbins = ip.Results.nbins;
	plotFlag = ip.Results.graph;
	searchBins = ip.Results.search(1) : ip.Results.search(2);

	% get the soma location
	soma = getSomaXYZ(neuron);
	% remove rows for soma/axon
	T = neuron.getCellNodes;
	if ~isempty(ind)
		T(ind,:) = [];
	end
	% remove the synapse annotations
	row = strcmp(T.LocalName, 'cell');
	T = T(row,:);
	% get the remaining locations
	xyz = T.XYZum;

	% remove Z-axis if needed
	if dim == 2
		xyz = xyz(:, 1:2);
		soma = soma(:,1:2);
	end

	% get the distance of each annotation from the soma
	somaDist = fastEuclid2d(soma, xyz);
	fprintf('soma distances range from %.2f to %.2f\n',...
		min(somaDist), max(somaDist));

	% create a histogram of soma distances
	if isempty(nbins)
		[n, edges, bins] = histcounts(somaDist);
	else
		[n, edges, bins] = histcounts(somaDist, nbins);
	end

	% get the dendrite sizes
	dendrite = T.Size;

	% splitapply will throw an error for empty bins
	emptyBins = find(n == 0);
	% lots of empty bins is generally not a good sign
	fprintf('Found %u empty bins\n', numel(emptyBins));
	% make sure each bin is represented - even if it's just with 0
	if ~isempty(emptyBins)
		bins = cat(1, bins, emptyBins');
		dendrite = cat(1, dendrite, zeros(numel(emptyBins),1));
	end


	% compute dendrite size stats for distance bins
	d.counts = n;
	d.edges = edges;
	d.avg = splitapply(@mean, dendrite, bins);
	d.std = splitapply(@std, dendrite, bins);
	d.sem = splitapply(@sem, dendrite, bins);
	% print some results
	fprintf('search window = %.2f to %.2f\n',...
		edges(searchBins(1)), edges(searchBins(2)));
	fprintf('mean diameter = %.2f +- %.2f\n',...
		mean(d.avg(searchBins)), mean(d.sem(searchBins)));
	d.median = splitapply(@median, dendrite, bins);
	fprintf('median diamter = %.2f\n',...
		mean(d.median(searchBins)));

	% save the params for later reference
	d.params.searchBins = searchBins;
	d.params.nbins = nbins;
	d.params.dim = dim;
	d.params.ind = ind;

	% plot the results
	if plotFlag
		figure('Name', sprintf('c%u dendrite analysis',...
			neuron.cellData.cellNum));
		hold on;
		errorbar(d.edges(2:end), d.avg, d.sem,...
			'k', 'LineWidth', 1);
		plot(d.edges(2:end), d.median,...
			'b', 'LineWidth', 1);
		% keep this for easy copy to other plots
		plot(d.edges(2:end), d.avg,'k', 'LineWidth', 1)
		legend('mean', 'median');
		set(legend, 'EdgeColor', 'w', 'FontSize', 10);
		xlabel('distance from soma (microns)');
		ylabel('avg dendrite diameter (microns)');
		set(gca, 'Box', 'off', 'TickDir', 'out');
		title(sprintf('c%u',...
			neuron.cellData.cellNum));
	end
