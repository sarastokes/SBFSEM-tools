function distFromSoma = fastEuclid3d(somaXYZ, targetXYZ)
	% Fast fcn for distance between 2 points
	% INPUTS:
	%		somaXYZ			main location (1x3)
	%		targetXYZ		target locations (N x 3)
	% OUTPUTS:
	%		distFromSoma	distances (N x 1)
	%
	% 18Jun2017 - SSP - created

	somaXYZ = repmat(somaXYZ, [size(targetXYZ,1) 1]);

	x = bsxfun(@minus, somaXYZ(:,1), targetXYZ(:,1));
	y = bsxfun(@minus, somaXYZ(:,2), targetXYZ(:,2));
	z = bsxfun(@minus, somaXYZ(:,3), targetXYZ(:,3));

	distFromSoma = sqrt(x.^2 + y.^2 + z.^2);
