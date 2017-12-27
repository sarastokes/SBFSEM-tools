function curveData = parseClosedCurve2(str, volumeScale)
	% PARSECLOSEDCURVE  Convert Mosaic string to data points
	%
	%	Inputs:
	%		str 		Closed curve string from OData
	%		volumeScale XYZ scale or volume name 
	%	Outputs:
	%		curveData
	%
	% 7Nov2017 - SSP 
	% 26Dec2017 - SSP - added micron conversion

	if ischar(volumeScale)
		volumeScale = validateSource(volumeScale);
		volumeScale = fetchODataScale(volumeScale);
	end

	% Convert scale from nm -> um if needed
	if max(volumeScale) > 1
		volumeScale = volumeScale./1e3;
	end

	% Cut out the last letters
	str(isletter(str)) = [];
	% The entire dataset is in parentheses, remove them
	str = str(3:end);
	% Each outline (parent and cutouts) is in parens too
	if numel(strfind(str, '(')) > 0
		% Remove the text between each parentheses
		try % Matlab2017
			curveStrings = extractBetween(str, '(', ')');
		catch % Older Matlab versions
			curveStrings = strsplit(str, '),');
			for i = 1:numel(curveStrings)
				tmp = curveStrings{i};
				curveStrings{i} = tmp(2:end-1);
			end
		end
		numCurves = numel(curveStrings);
	else
		curveStrings = str;
		numCurves = 1;
	end

	curveData = cell(numCurves, 1);

	for i = 1:numCurves
		% Split by commas into cell of {'x y'} values
		xyString = strsplit(curveStrings{i}, ', ');
		% Store the xy values in Nx2 matrix
		curvePoints = [];
		for j = 1:numel(xyString)
			curvePoint = strsplit(xyString{j}, ' ');
			% Scale to microns
			xpt = volumeScale(1) * str2double(curvePoint{1});
			ypt = volumeScale(2) * str2double(curvePoint{2});
			curvePoints = cat(1, curvePoints, [xpt ypt]);
		end
		curveData{i} = curvePoints;
	end

