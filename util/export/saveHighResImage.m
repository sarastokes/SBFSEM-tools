function saveHighResImage(fh, filePath, fileName)
	% SAVEHIGHRESIMAGE
	%
	% Inputs:
	%	fh 			figure handle
	%	fpath 		file path
	%	fname 		file name
	% -------------------------------------------------------

	if nargin < 3
		filePath = uiputfile();
	else
		filePath = [filePath, filesep, fileName];
	end

	switch fileName(end-2:end)
		case {'peg', 'jpg'}
			fileExt = '-djpeg';
		case {'tif', 'iff'}
			fileExt = '-dtiff';
		otherwise
			fileExt = '-dpng';
	end

	set(gcf, 'InvertHardcopy', 'off');

	print(gcf, filePath, fileExt, '-r600');