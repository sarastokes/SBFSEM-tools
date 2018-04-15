function curveData = parseClosedCurve(str)
	% PARSECLOSEDCURVE  
	%
	% Description:
	%	Convert Mosaic string to data points
	% 
	% Inputs: 
	%	str 		Imported odata mosaic geometry
	%
	% History:
	% 	7Nov2017 - SSP
	% ------------------------------------------------------------------

	% Cut out the letter characters
	str(isletter(str)) = [];
	% The entire dataset is inside parentheses, remove them
	str = str(3:end-1);
	% Each outline (parent and cut-outs) is in parens too
	if numel(strfind(str, '(')) > 0
		% Remove the text between each parentheses
        try % Matlab2017
    		curveStrings = extractBetween(str, '(', ')');
        catch % Older Matlab versions
            curveStrings = strsplit(str, '),');
            for i = 1:numel(curveStrings)
                tmp = curveStrings{i};
                a = strfind(tmp, '(');
                b = strfind(tmp, ')');
                if ~isempty(a) && numel(a) == 1
                    curveStrings{i} = tmp(a:end);
                end
                if ~isempty(b) && numel(b) == 1
                    curveStrings{i} = tmp(1:b);
                end
            end
        end
		numCurves = numel(curveStrings);
	else
		curveStrings = str;
		numCurves = 1;
	end

	curveData = cell(numCurves, 1);

	for i = 1:numCurves
        % There might be an extra paren
        if strcmp(curveStrings{i}(1), '(')
            curveStrings{i} = curveStrings{i}(2:end);
        end
		% Split by commas into cell of {'x y'} values
		xyString = strsplit(curveStrings{i}, ', ');
		% Store the xy values in Nx2 matrix
		curvePoints = [];
		for j = 1:numel(xyString)
			curvePoint = strsplit(xyString{j}, ' ');
			curvePoints = cat(1, curvePoints,...
				[str2double(curvePoint{1}), str2double(curvePoint{2})]);
		end
		curveData{i} = curvePoints;
	end