classdef (Abstract) BoundaryMarker < handle
	
	properties (SetAccess = private, GetAccess = public)
		volumeName
		baseURL
	end

	properties (Access = public)
        queryDate
        TYPEID
        units = 'microns'
        interpolationFcn
    end
    
    properties (Access = public, Transient = true)
        markerLocations = []
        interpolatedSurface = []
        newXPts
        newYPts
    end

	methods
		function obj = BoundaryMarker(source)
			obj.volumeName = validateSource(source);
			obj.baseURL = [getServerName(), obj.volumeName, '/OData/'];
        end
        
        function setUnits(obj, unitName)
            obj.units = validatestring(unitName, {'microns', 'pixels'});
            obj.refresh();
        end
   
        function refresh(obj)
            obj.updateMarkers();
            obj.calculateInterpolation();
        end
        
        function interpBoundary(obj, varargin)
            if isempty(obj.interpolationFcn) || isempty(obj.markerLocations)
                obj.refresh();
            end
            
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'x', [], @ismatrix);
            addParameter(ip, 'y', [], @ismatrix);
            addParameter(ip, 'npts', 100, @isnumeric);
            parse(ip, varargin{:});
            npts = ip.Results.npts;
            
            if isempty(ip.Results.x)
                x = linspace(min(obj.markerLocations(:,1)),...
                    max(obj.markerLocations(:,1)), npts);
            else
                x = ip.Results.x;
            end
            
            if isempty(ip.Results.y)
                y = linspace(min(obj.markerLocations(:,2)),...
                    max(obj.markerLocations(:,2)), npts);
            else
                y = ip.Results.y;
            end

            % Resample the original data points
            [obj.newXPts, obj.newYPts] = meshgrid(x, y);
            
            % Create a boundary surface spanning the new points
            obj.interpolatedSurface = obj.interpolationFcn(...
                obj.newXPts, obj.newYPts);
        end

        function plotRawData(obj)
            fh = sbfsem.ui.FigureView(1);
            surf(fh.ax, obj.markerLocations);
            shading(fh.ax, 'flat');
            fh.setColormap('redblue');
            fh.labelXYZ();
            fh.title('IPL Marker Surface');
        end

        function fh = plotSurface(obj, includeData)
            if nargin < 2 
                includeData = false;
            else
                assert(islogical(includeData),...
                    't/f include raw data');
            end
            fh = sbfsem.ui.FigureView(1);
            surf(fh.ax, obj.newXPts, obj.newYPts,...
                obj.interpolatedSurface);
            shading(fh.ax, 'flat');
            fh.setColormap('redblue');
            fh.labelXYZ();
            fh.title('IPL Boundary Surface');
            if includeData
                hold(fh.ax, 'on');
                if strcmp(obj.units, 'microns')
                    xyz = viking2micron(obj.markerLocations, obj.volumeName);
                else
                    xyz = obj.markerLocations;
                end
                scatter3(fh.ax, xyz(:, 1), xyz(:, 2), xyz(:,3), 'xk');
            end
        end
    end
    
    methods (Access = protected)        
        function calculateInterpolation(obj)
            if isempty(obj.markerLocations)
                obj.updateMarkers();
            end
            fprintf('Interpolating boundary with %u markers imported %s\n',...
                size(obj.markerLocations, 1), datestr(obj.queryDate));
            if strcmp(obj.units, 'microns')
                xyz = viking2micron(obj.markerLocations, obj.volumeName);
            else
                xyz = obj.markerLocations;
            end

            obj.interpolationFcn = scatteredInterpolant(...
                xyz(:,1), xyz(:,2), xyz(:,3));

            [obj.newXPts, obj.newYPts] = meshgrid(...  
                linspace(min(xyz(:,1)), max(xyz(:,1)), 100),...
                linspace(min(xyz(:,2)), max(xyz(:,2)), 100));
            obj.interpolatedSurface = obj.interpolationFcn(obj.newXPts, obj.newYPts);       
        end
        
		function updateMarkers(obj)
			data = readOData([obj.baseURL,...
				'Structures?$filter=TypeID eq ' num2str(obj.TYPEID),... 
				'&$select=ID']);
			markerIDs = struct2array(data.value);
            xyz = [];
            for i = 1:numel(markerIDs)
                data = readOData([obj.baseURL,...
                    'Structures(', num2str(markerIDs(i)), ')',...
                    '/Locations?$select=X,Y,Z']);
                xyz = cat(1, xyz, struct2array(data.value));
            end
            obj.markerLocations = xyz;
			obj.queryDate = datestr(now);
        end   
	end
end