function [counts, binCenters] = myhistcounts(x, numBins)
	% MYHISTCOUNTS  Returns bin centers not edges

	if nargin < 2
		[counts, bins] = histcounts(x);
	else
		[counts, bins] = histcounts(x, numBins);
	end

	binCenters = bins(1:end-1) + (bins(2)-bins(1))/2;