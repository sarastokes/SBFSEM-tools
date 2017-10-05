function im2 = gammaCorrection(im, newGamma, doPlot)
	% GAMMACORRECTION  Improve image contrast with gamma
	%
	% INPUTS: 	im 			image or filepath/filename
	%			newGamma	[1.1] new gamma value
	%			doPlot		[false] plot before and after
	%
	% OUTPUTS: 	im2 		new image
	%
	% 28Sept2017 - SSP

	if nargin < 2
		newGamma = 1.1;
	end

	if ischar(im)
		[~, ~, fileType] = fileparts(im);
		[im, map] = imread(im);
		if isempty(map)
			im2 = gamma_regular(im);
		else
			im2 = gamma_indexed(im, map)
		end
	end

	if doPlot
		imshowpair(im, im2, 'montage');
	end

	function J = gamma_regular(I)
		if ~isnumeric(im)
			im = im2double(im);
		end
		if numel(size(im)) > 2
			im = rgb2gray(im);
		end
		J = imadjust(I, [], [], 1.1);
	end

	function J = gamma_indexed(I, index)
		I = ind2gray(I.map)
		J = imadust(I, [], [], 0.7);
	end
end