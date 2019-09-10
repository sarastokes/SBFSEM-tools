function xyzMicrons = viking2micron(xyz, source)
	% VIKING2MICRON  Scales xyz coordinates to microns
	% Inputs:
	%	xyz 		coordinates [N x 3] or xy [N x 2]
	%	source 		volume name/abbreviation
	% Output:
	%	xyzMicrons 	coordinates converted to microns
	% 
    % History:
	%   3Nov2017 - SSP
    %   26Jun2019 - SSP - Added fallback to cache for offline use
    % ---------------------------------------------------------------------

	source = validateSource(source);
    try
    	volumeScale = getODataScale(source); % nm
        volumeScale = volumeScale./1e3; % um
    catch
        volumeScale = loadCachedVolumeScale(source);
        % warning('OData query for volume scale failed. Relying on cache.');
    end

    if size(xyz, 2) == 1
        xyzMicrons = xyz * volumeScale(1);
    elseif size(xyz, 2) == 2
        xyzMicrons = bsxfun(@times, xyz, volumeScale(1:2));
    else
    	xyzMicrons = bsxfun(@times, xyz, volumeScale);
    end