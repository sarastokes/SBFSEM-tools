classdef GeometryOData < sbfsem.io.OData
% GEOMETRYODATA  Responsible for importing Closed Curve geometry data
%
% Methods:
%   obj.pull()          Runs the query, parses the result
%
% 28Dec2017 - SSP
    
    properties (SetAccess = private)
        ID
        Query
        volumeScale         % microns
    end
    
    methods
        function obj = GeometryOData(ID, source)
            obj@sbfsem.io.OData(source);
            assert(isnumeric(ID), 'ID must be numeric');
            obj.ID = ID;

            obj.Query = [getServerName(), obj.source,...
                '/OData/Structures(', num2str(obj.ID),...
                ')\Locations?$filter=TypeCode eq 6'];
            
            volumeScale = getODataScale(obj.source); % nm
            obj.volumeScale = volumeScale .* 1e-3; % um

        end
        
        function geometryData = pull(obj)
            geometryData = obj.runQuery();
        end        
    end
    
    methods (Access = private)
        function geometries = runQuery(obj)
            
            geometries = [];
            importedData = readOData(obj.Query);
            
            for i = 1:numel(importedData.value)
                % Parse OData text
                closedCurves = obj.parseClosedCurve(...
                    importedData.value(i).MosaicShape.Geometry.WellKnownText,...
                    obj.volumeScale);
                % Add to geometry table
                geometries = [geometries; table(...
                    importedData.value(i).ID,...
                    importedData.value(i).ParentID,...
                    importedData.value(i).Z,...
                    importedData.value(i).Z * obj.volumeScale(3),...
                    {closedCurves})]; %#ok
            end
            
            geometries.Properties.VariableNames = {'ID', 'ParentID',...
                'Z', 'Zum', 'Curve'};
            % Order by Z section
            geometries = sortrows(geometries, 'Z', 'descend');
        end
    end
    
    methods (Static)
        function [curveData, curveSpline] = parseClosedCurve(str, volumeScale)
            % PARSECLOSEDCURVE  Convert Mosaic string to data points
            %
            %	Inputs:
            %		str             Closed curve string from OData
            %		volumeScale     XYZ scale or volume name
            %	Outputs:
            %		curveData       Control points
            %       curveSpline     Catmull-Rom splines
            %
            % 7Nov2017 - SSP
            % 26Dec2017 - SSP - added micron conversion
            % 28Dec2017 - SSP - moved to sbfsem.io.GeometryOData
            
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
                for j = 1:numel(xyString)-1
                    curvePoint = strsplit(xyString{j}, ' ');
                    % Scale to microns
                    xpts = volumeScale(1) * str2double(curvePoint{1});
                    ypts = volumeScale(2) * str2double(curvePoint{2});
                    curvePoints = cat(1, curvePoints, [xpts, ypts]);
                end
                curveData{i} = curvePoints;
            end            
        end
    end
end