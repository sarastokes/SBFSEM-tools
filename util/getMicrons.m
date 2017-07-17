function xyz = getMicrons(xyz, normFlag)
	% get microns from pixel location in viking
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
		for ii = 1:size(xyz, 2)
			xyz(:, ii) = xyz(:, ii) - min(xyz(:, ii));
		end
	end
