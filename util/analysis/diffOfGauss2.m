function dog = diffOfGauss2(im, cntr, sur)

	edges = ceil(size(cntr, 1)/2);
	if size(im, 1) <= 2 * edges || size(im, 1) <= 2*edges
		warndlg('image is too small');
	else
		imcen = conv2(im, cntr, 'same');
		imsur = conv2(im, sur, 'same');
		% divisive normalization
		dog = (imcen-imsur)./imsur;
		dog   = dog(edges+1:end-edges,edges+1:end-edges);
	end