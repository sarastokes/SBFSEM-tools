function z = getMicronsZ(z, normFlag)
	% get microns from pixel location in viking (3d)
	% INPUTS:
	%	xyz			location in viking in pixels
	% OPTIONAL:
	%	normFlag	normalize units (default = false)
	% 
	% 16Jul2017 - SSP - created

	% this is for NeitzInferior
	z = z .* 90;

	if normFlag
		z = z - min(z);
	end
