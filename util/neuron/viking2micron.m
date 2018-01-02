function xyzMicrons = viking2micron(xyz, source)
	% VIKING2MICRON  Scales xyz coordinates to microns
	% Inputs:
	%	xyz 		coordinates [N x 3] or xy [N x 2]
	%	source 		volume name/abbreviation
	% Output:
	%	xyzMicrons 	coordinates converted to microns
	% 
	% 3Nov2017 - SSP

	source = validateSource(source);
	volumeScale = getODataScale(source); % nm
    volumeScale = volumeScale./1e3; % um

    if size(xyz, 2) == 1
        xyzMicrons = xyz * volumeScale(1);
    elseif size(xyz, 2) == 2
        xyzMicrons = bsxfun(@times, xyz, volumeScale(1:2));
    else
    	xyzMicrons = bsxfun(@times, xyz, volumeScale);
    end