function distFromSoma = fastEuclid2d(somaXY, targetXY)
	% see fastEuclid3d
	%
	% 13Aug2017 - SSP - created

	somaXY = repmat(somaXY, [size(targetXY, 1) 1]);
	x = bsxfun(@minus, somaXY(:,1), targetXY(:,1));
	y = bsxfun(@minus, somaXY(:,2), targetXY(:,2));

	distFromSoma = sqrt(x.^2 + x.^2);