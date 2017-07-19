function xyz = getMicronsXY(xyz, source, normFlag)
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

	if strcmp(source, 'rc1')
		% 2.18nm per pixel
		xyz = 2.18 .* xyz;
	else
		% 5nm per pixel
		xyz = 5 .* xyz; % nm
	end
	xyz = xyz ./ 1000; % um

	if normFlag
		% subtract min from each column
		xyz = bsxfun(@minus, xyz, min(xyz));
	end
