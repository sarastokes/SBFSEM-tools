classdef TypeCodes < uint16
	
	enumeration
		CurvePolygon (1)
		LineString (5)
		Polygon (6)
	end


	methods 
		function ret = parse(obj)
			switch obj
				case 1
					disp('Use built-in');
				case 5 
					str(isletter(str)) = [];
					str = str(3:end-1);
					[x, y] = obj.splitToXY(str);
				case 6
					% Cut out the letter characters
					str(isletter(str)) = [];
					% The entire dataset is surrounded by parentheses, remove them
					str = str(3:end-1);
					% Separate out each outline
					if numel(strfind(str, '(')) > 0
						% Remove the text between parentheses
						curveStrings = extractBetween(str, '(', ')'));
						numCurves = numel(curveStrings);
					else
						curveStrings = str;
						numCurves = 1;
					end
					curveData = cell(numCurves, 1);
					for i = 1:numCurves
						% Split by commas into cell of {'x y'} values
						xyString = strsplit(curveStrings, ', '); 
						% Store the xy values in Nx2 matrix
						curvePoints = [];
						for j = 1:numel(xyString)
							curvePoint = strsplit(xyString{j}, ' ');
							curvePoints = cat(1, curvePoints,...
								[str2double(curvePoint{1}), str2double(curvePoint{2})]);
						end
						curveData{i} = curvePoints;
					end
				otherwise
					disp('Type not yet supported');
			end
		end
	end
end