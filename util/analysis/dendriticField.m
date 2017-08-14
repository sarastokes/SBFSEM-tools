function dendrite = dendriticField(neuron, coordinates)
	% DENDRITICFIELD  Get dendritic field estimates
	%
	% INPUTS:
	%	neuron 		Neuron object
    %   coordinates 'cartesian', 'polar'
	% OUTPUTS:
	%
	% 5Aug2017 - SSP - created
    
    if nargin < 2
        coordinates = 'cartesian';
    end

	% get cell locations in microns
	rows = strcmp(neuron.dataTable.LocalName, 'cell');
	XYZ = neuron.dataTable.XYZum(rows, :);

	% get soma location in microns
	soma = getSomaXYZ(neuron);

	% set the soma location to (0,0,0)
	xyz = bsxfun(@minus, XYZ, soma);
	% distance not location
	% xyz = abs(xyz);


    dendriteSize = neuron.dataTable.Size(rows, :);
    
    % convert to polar coordinates
    if strcmp(coordinates, 'polar')
    	[theta, rho, ~] = cart2pol(xyz(:,1), xyz(:,2), xyz(:,3));
        [N, edges, bins] = histcounts(rho);
        dendrite.max = max(rho);
        dendrite.theta = theta;
        dendrite.rho = rho;
    else
        somaDist = fastEuclid3d(soma, xyz);
        [N, edges, bins] = histcounts(somaDist);
        dendrite.max = max(somaDist);
    end

	c = 0.5 * (edges(2) - edges(1));
	dendrite.bins = linspace(edges(1) + c, edges(end) - c, length(N));

	% catch empty bin errors
	ind = find(N == 0);
	% make sure each bin is represented - even if it's just with 0
	if ~isempty(ind)
		bins = cat(1, bins, ind);
		dendriteSize = cat(1, dendriteSize, zeros(numel(ind)));
	end
	dendrite.meanSize = splitapply(@mean, dendriteSize, bins);
	dendrite.sumSize = splitapply(@sum, dendriteSize, bins);
	dendrite.counts = splitapply(@numel, dendriteSize, bins);
	dendrite.std = splitapply(@std, dendriteSize, bins);
	

