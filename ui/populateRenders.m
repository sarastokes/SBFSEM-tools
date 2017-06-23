function fileNames = populateRenders(cellNum)
	% get blender render file names
    % Work in progress - currently only searches one directory for file
    % names matching c#... issue: searching for c2 will return all of the
    % files for c207, etc.
	%
	% 21Jun2017 - SSP - created

	renderDir = getFilepaths('render');
	files = dir(renderDir);
	fileNames = [];
	for ii = 1:size(files,1)
		if files(ii).isdir == 0
			if ~isempty(regexp(files(ii).name, ['c' num2str(cellNum)], 'once'))
				fileNames = [fileNames '___' files(ii).name];
			end
		end
	end
	if isempty(fileNames)
		fprintf('no blender renders found\n');
    else
        fileNames(1:3) = [];
		fileNames = regexp(fileNames, '___', 'split');
        fprintf('found %u blender files\n', length(fileNames));
	end