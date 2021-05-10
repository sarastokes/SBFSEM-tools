function D = fastEuclid2d(mainXYZ, XYZ)
	% FASTEUCLID2D
	%
    % Description:
	%   Fast fcn for Euclidean distance between 2 points
    %
    % Syntax:
    %   D = fastEuclid3d(mainXYZ, XYZ);
    %
    % See also:
    %   FASTEUCLID3D
    % 
    % History:
	%   13Aug2017 - SSP - created
    %   31Dec2020 - SSP - Updated to match fastEuclid3d
    % ---------------------------------------------------------------------
    
    if size(mainXYZ) ~= size(XYZ)
    	mainXYZ = repmat(mainXYZ, [size(XYZ, 1) 1]);
    end

	dx = bsxfun(@minus, mainXYZ(:,1), XYZ(:,1));
	dy = bsxfun(@minus, mainXYZ(:,2), XYZ(:,2));
    
	D = sqrt(dx.^2 + dy.^2);
