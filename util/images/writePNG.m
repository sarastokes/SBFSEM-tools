function writePNG(im, fname, fpath)
	% WRITEPNG  Lab-specific version of imwrite()
	%
	% 28Sept2017 - SSP

	if nargin == 3
		fname = [fpath filesep fname];
	end

	im = imwrite(im, fname, 'png',... 
		'Author', 'SaraPatterson_NeitzLab_UW');