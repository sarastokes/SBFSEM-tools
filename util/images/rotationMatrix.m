function x = rotationMatrix(theta)

	x = [cos(theta) -sin(theta);
		sin(theta) cos(theta)];