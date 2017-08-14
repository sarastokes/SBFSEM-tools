function d = dendriteSize(neuron, wind, varargin)
	% DENDRITESIZE  Return diameters at a specific distance
	%
	% 13Aug2017 - SSP - created

	ip = inputParser();
	ip.addParameter('dim', 2, @(x) ismember(x, [2 3]));
	ip.addParameter('ind', [], @isvector);
	ip.parse(varargin{:});
	dim = ip.Results.dim;
	ind = ip.Results.ind;

	% get the soma location
	soma = getSomaXYZ(neuron);
	% remove rows for soma/axon
	T = neuron.dataTable;
	if ~isempty(ind)
		T(ind,:) = [];
	end
	% remove the synapse annotations
	row = strcmp(T.LocalName, 'cell');
	T = T(row,:);
	% get the remaining locations
	xyz = T.XYZum;
	% radii -> diameter
	dendrite = 2 * T.Size;

	% remove Z-axis if needed
	if dim == 2
		xyz = xyz(:, 1:2);
		soma = soma(:,1:2);
	end

	% get the distance of each annotation from the soma
	somaDist = fastEuclid2d(soma, xyz);
	fprintf('soma distance range = %.2f to %.2f\n',... 
		min(somaDist), max(somaDist));

	% find the locations outside search range
	ind = find(somaDist < wind(1) & somaDist > wind(2));
	% remove them from dendrite size list
	dendrite(ind) = [];

	% run some stats and save the results
	d = struct();
	d.n = numel(dendrite);
	fprintf('%u in search window\n', d.n);
	d.avg = mean(dendrite);
	d.sem = sem(dendrite);
	fprintf('mean diameter = %.2f +- %.2f\n',... 
		d.avg, d.sem);
	d.std = std(dendrite);
	d.median = median(dendrite);
	fprintf('median diameter = %.2f, radius = %.2f\n',... 
		d.median, d.median/2);
	d.wind = wind;


