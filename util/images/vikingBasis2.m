function mat = vikingBasis2(im, blueXY, mag)
	
	mat = getImageRGB(im, [0 1 0], true);
	blue = getImageRGB(im, [1 0 0], true);
	blue = median(blue,2);
	
	mat = mag * mat;
	blue = mag * blue;
	
	offset = blueXY-blue;
	
	mat(1,:) = bsxfun(@plus, offset(1), mat(1,:));
	mat(2,:) = bsxfun(@plus, offset(2), mat(2,:));