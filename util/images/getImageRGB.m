function mat = getImageRGB(im, rgb, rotFlag) %#ok<INUSD>
	% GETIMAGERGB  
    %
    % Description:
    %   Return index of pixels matching RGB
	%
    % INPUTS:
    %   im          image (x*y*3)
    %   rgb         target RGB values
    %   rotFlag     transpose output (default = false)
    % OUTPUTS:
    %   r, c        row/columns matching RGB value
    %
	% 15Aug2017 - SSP - created
    % 11May2018 - SSP - Generalized: rm clipFlag, auto rotation
	% ------------------------------------------------------------------
    if ~isa(im, 'double')
        im = im2double(im);
    end
    if nargin < 3
        rotFlag = false;
    end
    
    % Old clip toolbar option
    % if nargin == 3
    %     im = im(1:end-100,:,:);
    % end
	
	[m, n, t] = size(im);
	im = reshape(im, [m*n t]);
	
	% Get the points matching all 3 RGB values
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

        mat = [r, c];
        if rotFlag
            mat = mat';
        end
    end
end