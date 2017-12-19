classdef (Abstract) BoundaryMarker < handle
	
	properties (SetAccess = private, GetAccess = public)
		source
		baseURL
	end

	properties (Access = public)
        queryDate
        TYPEID
        units = 'microns'
        interpolatedSurface = []
    end
    
    properties (Access = public, Transient = true)
        markerLocations = []
        newXPts
        newYPts
    end

    properties (Constant = true)
        SMOOTHFAC = 0.005;
    end

	methods
		function obj = BoundaryMarker(source)
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), obj.source, '/OData/'];
        end
        
        function setUnits(obj, unitName)
            obj.units = validatestring(unitName, {'microns', 'pixels'});
            obj.pull();
        end
   
        function update(obj)
            obj.pull();
        end
        
        function doAnalysis(obj, numPts)
            if isempty(obj.markerLocations)
                obj.refresh();
            end
            
            if nargin < 2 
                numPts = 100;
            end
            
            % Create a new grid of points to sample from
            ptsRange = [floor(min(obj.markerLocations)); ceil(max(obj.markerLocations))];
            if strcmp(obj.units, 'microns')
                ptsRange = viking2micron(ptsRange, obj.source);
            end

            obj.newXPts = linspace(ptsRange(1,1), ptsRange(2,1), numPts);          
            obj.newYPts = linspace(ptsRange(1,2), ptsRange(2,2), numPts);

            obj.interpolatedSurface = obj.getSurface();
        end

        function fh = plot(obj, includeData)
            if nargin < 2 
                includeData = false;
            else
                assert(islogical(includeData),...
                    't/f include raw data');
            end
            fh = sbfsem.ui.FigureView(1);
            hold(fh.ax, 'on');
            surf(fh.ax, obj.newXPts, obj.newYPts,...
                obj.interpolatedSurface,...
                'FaceAlpha', 0.8);
            shading(fh.ax, 'interp')
            fh.labelXYZ();
            fh.title('IPL Boundary Surface');
            if includeData
                hold(fh.ax, 'on');
                if strcmp(obj.units, 'microns')
                    xyz = viking2micron(obj.markerLocations, obj.source);
                else
                    xyz = obj.markerLocations;
                end
                scatter3(fh.ax, xyz(:, 1), xyz(:, 2), xyz(:,3), 'fill');
            end
            view(fh.ax, 3);
        end

        function addToScene(obj, ax, markerSize)
            if nargin < 3
                markerSize = 25;
            end
            assert(ishandle(ax), 'Input an axes handle to plot to');
            if strcmp(obj.units, 'microns')
                xyz = viking2micron(obj.markerLocations, obj.source);
            else
                xyz = obj.markerLocations;
            end
            hold(ax, 'on');
            scatter3(ax, xyz(:,1), xyz(:,2), xyz(:,3), 'ViewSize', markerSize);
        end
    end
    
    methods (Access = protected)   
        function z = getSurface(obj)
            % 9Dec2017 - SSP - changed from scatteredInterpolant
            
            if strcmp(obj.units, 'microns')
                xyz = viking2micron(obj.markerLocations, obj.source);
            else
                xyz = obj.markerLocations;
            end

            z = RegularizeData3D(xyz(:,1), xyz(:,2), xyz(:,3),...
                obj.newXPts, obj.newYPts,...
                'interp', 'bicubic', 'smoothness', obj.SMOOTHFAC);
        end
        
		function pull(obj)
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