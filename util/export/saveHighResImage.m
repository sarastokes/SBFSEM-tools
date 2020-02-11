function saveHighResImage(figureHandle, filePath, fileName)
	% SAVEHIGHRESIMAGE
	%
	% Inputs:
	%	fh 			figure handle
	%	fpath 		file path
	%	fname 		file name
	% -------------------------------------------------------

    if nargin < 3
        filePath = uiputfile(...
            {'*.png', '*.tif', '*.jpg'},...
            'Save image');
        if isempty(filePath)
            return;
        end
    else
        filePath = [filePath, filesep, fileName];
    end
    
    if nargin < 1
        figureHandle = gcf;
    end

	switch fileName(end-2:end)
		case {'peg', 'jpg'}
			fileExt = '-djpeg';
		case {'tif', 'iff'}
			fileExt = '-dtiff';
		otherwise
			fileExt = '-dpng';
	end

	set(figureHandle, 'InvertHardcopy', 'off');

	print(figureHandle, filePath, fileExt, '-r600');