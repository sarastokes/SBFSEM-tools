function mag =  euclideanDist2(xyz)
	% 25Sept2018 - SSP

	mag = sqrt((diff(xyz(:, 1))).^2 + (diff(xyz(:, 2))).^2);
