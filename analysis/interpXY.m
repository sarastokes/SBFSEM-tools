function f = interpXY(xyz, numBins, plotFlag)
	% bins up data and returns scatteredInterpolant object
	%
	% INPUTS:
	%	xyz			locations in viking
	%	numBins		[x y]
	% OPTIONAL:
	%	plotFlag	true
	% OUTPUT:
	%	f 			griddedInterpolant object
	%
	% 19Jun2017 - SSP - created

	for ii = 1:numBins

	f = scatteredInterpolant(binX, binY, );