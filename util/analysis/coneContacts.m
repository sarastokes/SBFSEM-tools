function [cp, fh] = coneContacts(neuron, cutoff, varargin)
	% CONECONTACTS  Creates a histogram of processes in cone
	% INPUT:
	%	neuron		neuron object
	%	cutoff		max z-axis point to include
	% OPTIONAL:
	%	res 		[1] sections per bin 
	% OUTPUT:
	%	cp			structure of results
	%	fh 			plot results (only if fh is specified)

	ip = inputParser();
	ip.addParameter('groupStruct', [], @isstruct);
	ip.addParameter('res', 1, @isnumeric);
	ip.parse(varargin{:});
	res = ip.Results.res;
	groupStruct = ip.Results.groupStruct;

	row = strcmp(neuron.dataTable.LocalName, 'cell')... 
		& neuron.dataTable.XYZum(:,3) >= cutoff;
	xyz = neuron.dataTable.XYZum(row,:);
	dendrite = neuron.dataTable.Size(row,:);

	numBins = numel(unique(xyz(:,3)));
	numBins = numBins / res;
	[n, edges, bins] = histcounts(xyz(:,3), numBins);

	% splitapply will throw an error for empty bins
	emptyBins = find(n == 0);
	% lots of empty bins is generally not a good sign
	fprintf('Found %u empty bins\n', numel(emptyBins));
	% make sure each bin is represented - even if it's just with 0
	if ~isempty(emptyBins)
		bins = cat(1, bins, emptyBins');
		dendrite = cat(1, dendrite, zeros(numel(emptyBins),1));
	end

	% get dendrite size in each bin
	ds = splitapply(@sum, dendrite,bins);

	% keep the stats
	name = sprintf('c%u', neuron.cellData.cellNum);
	if isempty(groupStruct)
		cp = struct();
	else % check for existing field
		if ~isfield(groupStruct, name)
			groupStruct.(name) = struct();
		end
		cp = groupStruct.(name);
	end
	cp.n = n;
	cp.edges = edges;
	cp.res = res;
	cp.cutoff = cutoff;
	cp.ds = ds';
	cp.metric = cp.ds .* cp.n;

	if nargout > 1
		fh = figure(); hold on;
		plot(cp.ds .* cp.n, edges(2:end),... 
			'k', 'LineWidth', 1.5);
		xlabel('annotation count'); ylabel('z-axis section');
		title(sprintf('c%u stratification at cone pedicle',... 
			neuron.cellData.cellNum));
		set(gca, 'YDir', 'reverse',... 
			'Box', 'off', 'TickDir', 'out');
	end
