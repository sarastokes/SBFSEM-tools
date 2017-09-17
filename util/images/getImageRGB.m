function mat = getImageRGB(im, rgb, clipFlag) %#ok<INUSD>
	% GETIMAGERGB  Return index of pixels matching RGB
	%
    % INPUTS:
    %   im          image (x*y*3)
    %   rgb         target RGB values
    %   clipFlag    cut out toolbar from image
    % OUTPUTS:
    %   r, c        row/columns matching RGB value
    %
	% 15Aug2017 - SSP - created
	
    if ~isa(im, 'double')
        im = im2double(im);
    end
    
    if nargin == 3
        im = im(1:end-100,:,:);
    end
	
	[m, n, t] = size(im);
	im = reshape(im, [m*n t]);
	
	% get the points matching all 3 RGB values
	ind = zeros(m*n, 1);
	for ii = 1:3
		ind = ind + bsxfun(@eq, rgb(ii), im(:,ii));
	end
	ind(ind < 3) = 0;
    if ~nnz(ind)
        fprintf('No pixels with rgb = [%u %u %u]\n', rgb);
        mat = [];
    else
    	ind = reshape(ind, [m n]);
	
        [r, c] = find(ind);
    
        %mat = rotateZ(r, c, -90);
        mat = [r,c]';
    end

end