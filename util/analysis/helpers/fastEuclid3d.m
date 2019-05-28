function D = fastEuclid3d(mainXYZ, XYZ)
    % FASTEUCLID3D
    %
    % Description:
	%   Fast fcn for Euclidean distance between 2 points
    %
    % Syntax:
    %   D = fastEuclid3d(mainXYZ, XYZ);
    %
	% INPUTS:
	%		mainXYZ			Main location (1x3)
	%		XYZ             Comparison locations (N x 3)
	% OUTPUTS:
	%		distFromSoma	Distance(s) from main location (N x 1)
	%
    % History:
	%   18Jun2017 - SSP - created
    %   25May2019 - SSP - added support for equally sized XYZ arrays
    % ---------------------------------------------------------------------

    if size(mainXYZ) ~= size(XYZ)
    	mainXYZ = repmat(mainXYZ, [size(XYZ, 1) 1]);
    end

	dx = bsxfun(@minus, mainXYZ(:,1), XYZ(:,1));
	dy = bsxfun(@minus, mainXYZ(:,2), XYZ(:,2));
	dz = bsxfun(@minus, mainXYZ(:,3), XYZ(:,3));

	D = sqrt(dx.^2 + dy.^2 + dz.^2);
