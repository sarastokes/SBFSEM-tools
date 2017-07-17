function xyz = getMicronXY(xyz, normFlag)
	% get microns from pixel location in viking (XY)
	% INPUTS:
	%	xyz			location in viking in pixels
	% OPTIONAL:
	%	normFlag	normalize units (default = false)
	% 
	% 16Jul2017 - SSP - created

	if nargin < 2
		normFlag = false;
	end

	% 5nm per pixel
	xyz = 5 .* xyz; % nm
	xyz = xyz ./ 1000; % um

	if normFlag
		% subtract min from each column
		xyz = bsxfun(@minus, xyz, min(xyz));
	end
