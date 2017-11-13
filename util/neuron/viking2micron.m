function xyzMicrons = viking2micron(xyz, source)
	% VIKING2MICRON  Scales xyz coordinates to microns
	% Inputs:
	%	xyz 		coordinates [N x 3]
	%	source 		volume name/abbreviation
	% Output:
	%	xyzMicrons 	coordinates converted to microns
	% 
	% 3Nov2017 - SSP

	source = validateSource(source);
	volumeScale = getODataScale(source);

	xyzMicrons = bsxfun(@times, xyz, volumeScale);