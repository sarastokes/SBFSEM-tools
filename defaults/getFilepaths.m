function x = getFilepaths(dirType)
	% get/set default filepaths
    % INPUTS: dirType          'save', 'import', 'export'
    %
    % There's an option to pick a directory in the GUI but having a default 
    % will save some time
    % 19Jun2017 - SSP - created


	% fill in the filepath to your 'data' folder containing 'temporal' and
	% 'inferior' subfolders: 'C:\...\data'
	saveDir = '';
    
    % file path where you export .json files
    jsonDir = '';
    
    % if you're going to be exporting to .csv, fill in a default:
    exportDir = '';

    % to import blender renders
    
    renderDir = 'C:\Users\sarap\Google Drive\NEITZ Lab\Electron Microscopy Rm\Blender Images\new figures\';
    if ~isdir(renderDir)
        renderDir = 'C:\Users\brian\Google Drive\NEITZ Lab\Electron Microscopy Rm\Blender Images\new figures\';
    end
    
    switch dirType
        case 'save'
            x = saveDir;
        case 'import'
            x = jsonDir;
        case 'export'
            x = exportDir;
        case 'render'
            x = renderDir;
    end