function mat = vikingBasis(im, blueXY, redXY)
	% VIKINGBASIS  Convert tracing into viking coordinates
	
	% The outline is traced in green 
	mat = getImageRGB(im, [0 1 0], true);
	
	% start point is in blue, end in red
	blue = getImageRGB(im, [0 0 1], true);
	red = getImageRGB(im, [1 0 0], true);
    % get the midpoints 
    blue = median(blue, 2);
    red = median(red, 2);
    
	% set blue point as the origin
	mat(1,:) = bsxfun(@minus, mat(1,:), blue(1));
    mat(2,:) = bsxfun(@minus, mat(2,:), blue(2));
	red = red - blue;
	
	% get the distance between blue and red annotations
	% pixelDist = red - blue;
	pixelDist = fastEuclid2d(red', blue');
    % get the distance in viking coordinates
	% vikingDist = redXY - blueXY;
    vikingDist = fastEuclid2d(redXY, blueXY);
    
	
	% this is the scale factor
	% fac = vikingDist'./ pixelDist;
	fac = vikingDist / pixelDist;
    
	% apply the scale factor to x and y
    mat = fac * mat;
	% mat(1,:) = bsxfun(@times, mat(1,:), fac(1));
	% mat(2,:) = bsxfun(@times, mat(2,:), fac(2));
	
	% blueXY is the offset
	mat(1,:) = bsxfun(@plus, mat(1,:), blueXY(1));
    mat(2,:) = bsxfun(@plus, mat(2,:), blueXY(2));