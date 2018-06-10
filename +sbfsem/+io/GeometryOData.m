classdef GeometryOData < sbfsem.io.OData
% GEOMETRYODATA  
% 
% Description:
%   Responsible for importing Closed Curve geometry data
%
% Constructor:
%   obj = GeometryOData(ID, source)
%
% Inputs:
%   ID                  Neuron structure ID
%   source              Volume name or abbreviation
%
% Properties:
%   ID                  Neuron structure ID
%   Query               OData query to get ClosedCurve data
%   volumeScale         Volume dimensions in (nm/pix, nm/pix, nm/slice)
%
% Public methods:
%   obj.pull()          Runs the query, parses the result
%
% History:
%   28Dec2017 - SSP
%   5Mar2017 - SSP - Updated for new JSON decoder
% -------------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
        Query
        volumeScale         % microns
    end
    
    methods
        function obj = GeometryOData(ID, source)
            % GEOMETRYODATA  Constructor
            obj@sbfsem.io.OData(source);
            assert(isnumeric(ID), 'ID must be numeric');
            obj.ID = ID;

            obj.Query = [getServiceRoot(obj.source),...
                'Structures(', num2str(obj.ID),...
                ')/Locations?$filter=TypeCode eq 6'];
            
            volumeScale = getODataScale(obj.source); % nm
            obj.volumeScale = volumeScale .* 1e-3; % um

        end
        
        function geometryData = pull(obj)
            % PULL  Run the OData query and parse results
            geometryData = obj.runQuery();
        end        
    end
    
    methods (Access = private)
        function geometries = runQuery(obj)
            % RUNQUERY  OData query for ClosedCurve data
            geometries = [];
            importedData = readOData(obj.Query);
            % Exit if no closed curve annotations found
            if isempty(importedData.value)
                geometries = [];
                return
            end
            value = cat(1, importedData.value{:});
            
            for i = 1:numel(value)
                % Parse OData text
                closedCurves = obj.parseClosedCurve(...
                    value(i).MosaicShape.Geometry.WellKnownText,...
                    obj.volumeScale);
                % Add to geometry table
                geometries = [geometries; table(...
                    value(i).ID,...
                    value(i).ParentID,...
                    value(i).Z,...
                    value(i).Z * obj.volumeScale(3),...
                    {closedCurves})]; %#ok
            end
            
            geometries.Properties.VariableNames = {'ID', 'ParentID',...
                'Z', 'Zum', 'Curve'};
            % Order by Z section
            geometries = sortrows(geometries, 'Z', 'descend');
        end
    end
    
    methods (Static)
        function curveData = parseClosedCurve(str, volumeScale)
            % PARSECLOSEDCURVE  Convert Mosaic string to data points
            %
            %	Inputs:
            %		str             Closed curve string from OData
            %		volumeScale     XYZ scale or volume name
            %	Outputs:
            %		curveData       Closed curve control points
            %
            % 7Nov2017 - SSP
            % 26Dec2017 - SSP - added micron conversion
            % 28Dec2017 - SSP - moved to sbfsem.io.GeometryOData
            % -------------------------------------------------------------
            
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