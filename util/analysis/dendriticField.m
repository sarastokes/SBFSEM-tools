function dendrite = dendriticField(neuron)
	% DENDRITICFIELD  Get dendritic field estimates
	%
	% INPUTS:
	%	neuron 		Neuron object
	% OUTPUTS:
	%
	% 5Aug2017 - SSP - created

	% get cell locations in microns
	rows = strcmp(neuron.dataTable.LocalName, 'cell');
	XYZ = neuron.dataTable.XYZum(rows, :);

	% get soma location in microns
	soma = getSomaXYZ(neuron);

	% set the soma location to (0,0,0)
	xyz = bsxfun(@minus, XYZ, soma);
	xyz = abs(xyz);

	% convert to polar coordinates
	[theta, rho, z] = cart2pol(xyz(:,1), xyz(:,2), xyz(:,3));
	dendriteSize = neuron.dataTable.Size(rows, :);

	[N, edges, bins] = histcounts(rho);

	c = 0.5 * (edges(2) - edges(1));
	dendrite.bins = linspace(edges(1) + c, edges(end) - c, length(N));

	% catch empty bin errors
	ind = find(N == 0);
	if ~isempty(ind)
		bins = cat(1, bins, ind);
		dendriteSize = cat(1, dendriteSize, zeros(numel(ind)));
	end
	dendrite.sizes = splitapply(@mean, dendriteSize, bins);