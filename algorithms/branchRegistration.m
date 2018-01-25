function [xyOffset, offsetList] = branchRegistration(source, sections, writeToLog, visualize)
	% BRANCHREGISTRATION
    %
    % Description:
    % 
    % Syntax:
    %	XY = branchRegistration(SOURCE, SECTIONS, WRITETOLOG, VISUALIZE);
    %
    % Example:
    %   branchRegistration('i', [1121 1122], false, true);
	% 
	% History:
	%	22Jan2018 - SSP
    % ---------------------------------------------------------------------

    if nargin < 3
        writeToLog = false;
    end
    if nargin < 4
    	visualize = false;
    end

	source = validateSource(source);
	template = ['/Locations?$filter=Z eq %u and TypeCode eq 1',...
				'&$select=ID,ParentID,VolumeX,VolumeY,Z'];
	propNames = {'ID', 'ParentID', 'X', 'Y', 'Z'};

	% Query and process data from vitread (min) section
	data = readOData([getServiceRoot(source),...
		sprintf(template, min(sections))]);
	vitread = struct2table(data.value);
	vitread.Properties.VariableNames = propNames;
	vitread = catchFalse(vitread);

	% Query and process data from sclerad (max) section 
	data = readOData([getServiceRoot(source),...
		sprintf(template,  max(sections))]);
	sclerad = struct2table(data.value);
	sclerad.Properties.VariableNames = propNames;
	sclerad = catchFalse(sclerad);

	% Get the IDs
	vitreadIDs = unique(vitread.ParentID);
	scleradIDs = unique(sclerad.ParentID);

	% Remove IDs in sclerad that aren't in vitread
	invalid = setdiff(scleradIDs, vitreadIDs);
	if ~isempty(invalid)
		sclerad(ismember(sclerad.ParentID, invalid), :) = [];
	end
	fprintf('Analyzing %u locations from %u neurons\n',...
		height(sclerad), numel(scleradIDs)-numel(invalid));

	linkQuery = [getServiceRoot(source),...
		'Locations(%u)?$select=ID&$expand=LocationLinksA',...
		'($select=A,B)'];

	% Calculate offsets: SCLERAD - VITREAD
	offsetList = [];
	for i = 1:height(sclerad)
		data = readOData(sprintf(linkQuery, sclerad.ID(i)));
		for j = 1:numel(data.LocationLinksA)
			linkedID = data.LocationLinksA(j).B;
			linkedLoc = vitread{find(vitread.ID == linkedID),{'X', 'Y'}};
			if ~isempty(linkedLoc)
				xyOffset = sclerad{i, {'X', 'Y'}} - linkedLoc;
				offsetList = [offsetList; xyOffset]; %#ok
			end
		end
    end

    try
    	printStat(offsetList(:,1));
        printStat(offsetList(:,2));
    end
	xyOffset = median(offsetList);

	if visualize
		figure(); hold on;
		plot(offsetList(:,1), offsetList(:,2),...
			'.b', 'MarkerSize', 10);
		plot(xyOffset(1), xyOffset(2),...
			'or', 'MarkerFaceColor', 'r');
		title(sprintf('X = %.3g and Y = %.3g', xyOffset));
	end
	
	if writeToLog
		fPath = [fileparts(fileparts(mfilename('fullpath'))),... 
            '\data\XY_OFFSET_NEITZINFERIORMONKEY.txt'];
		data = dlmread(fPath);
		% data = dlmread([fileparts(fileparts(mfilename('fullpath'))),...
		% 	'\data\XY_OFFSET_NEITZINFERIORMONKEY.txt']);
		Z = min(sections);
	   	data(1:Z, 2) = data(1:Z, 2) + xyOffset(1);
    	data(1:Z, 3) = data(1:Z, 3) + xyOffset(2);

    	dlmwrite(fPath, data);

		% fprintf('%s - branch registration\n', datestr(now));
		% fprintf('\tScleradZ VitreadZ Locations Neurons XOffset YOffset XSEM YSEM\n');
		% fprintf('\t%u %u %u %u %u %u %.3g %.3g\n\n',...
		% 	min(sections), max(sections),...
		% 	height(sclerad), numel(scleradIDs)-numel(invalid),...
		% 	median(offsetList), sem(offsetList));
	end
end

function T = catchFalse(T)	
	% CATCHFALSE  Remove annotations with X/Y = 0
	T(T.X == 0 | T.Y == 0, :) = [];
end