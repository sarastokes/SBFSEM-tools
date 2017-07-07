function x = getFilepaths(dirType)
	% get/set default filepaths
    % INPUTS: dirType          'data', 'render'
    %
    % There's an option to pick a directory in the UI but having a default 
    % will save some time.
    % 19Jun2017 - SSP - created


	% fill in the filepath to your 'data' folder containing 'temporal' and
	% 'inferior' subfolders: 'C:\...\data'
	dataDir = '';

    % folder where you save blender renders and other images
    renderDir = '';

    switch dirType
        case 'render'
            x = renderDir;
        case 'data'
            x = dataDir;
    end

