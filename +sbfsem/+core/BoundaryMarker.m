classdef (Abstract) BoundaryMarker < handle
    % BOUNDARYMARKER
    %
    % Description:
    %   Abstract class parent for IPL-GCL and INL-IPL boundary markers
    %
    % Constructor:
    %   obj = BoundaryMarker(source)
    %
    % Inputs:
    %   source          volume name or abbreviation (char)
    %
    % Methods:
    %   obj.update();
    %   obj.doAnalysis();
    %   obj.plot(varargin);
    %   obj.addToScene(ax, varargin); 
    %   obj.rmFromScene(ax);
    %
    % 11Nov2017 - SSP
    % 4Jan2018 - SSP - standardized function names
    % 7Feb2018 - SSP - better plotting, add and remove from scene methods
    % ---------------------------------------------------------------------
	
	properties (Hidden, Access = private)
		source
		baseURL
	end

	properties (SetAccess = private)
        queryDate
        units = 'microns'
        interpolatedSurface = []
    end
    
    properties (SetAccess = protected)
        TYPEID
    end
    
    properties (SetAccess = private, Transient = true)
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
            % UPDATE  Pull boundary markers from OData 
            obj.pull();
        end
        
        function doAnalysis(obj, numPts)
            % DOANALYSIS 
            %
            % Optional input:
            %   numPts      number of x and y points for fitting grid (100)
            % -------------------------------------------------------------
            if isempty(obj.markerLocations)
                obj.update();
            end
            
            if nargin < 2 
                numPts = 100;
            end
            
            % Create a new grid of points to sample from
            ptsRange = [floor(min(obj.markerLocations));... 
                        ceil(max(obj.markerLocations))];
            if strcmp(obj.units, 'microns')
                ptsRange = viking2micron(ptsRange, obj.source);
            end

            obj.newXPts = linspace(ptsRange(1,1), ptsRange(2,1), numPts);          
            obj.newYPts = linspace(ptsRange(1,2), ptsRange(2,2), numPts);

            obj.interpolatedSurface = obj.getSurface();
        end
        
        function Vq = xyEval(obj, x, y)
            % XYEVAL
            %
            % Inputs:
            %   x       X-axis location (vector)
            %   y       Y-axis location (vector)
            % ---------------------------------------------------------
            
            % Evaluate surface at XY point
            Vq = interp2(obj.newXPts, obj.newYPts,...
                obj.interpolatedSurface, x, y);            
        end

        function [fh, p] = plot(obj, varargin)
            % PLOT  
            % 
            % Optional key/value inputs:
            %   showData        Show annotations (default=false)
            %   ax              Figure or axes handle (default=new)
            % -------------------------------------------------------------
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'showData', false, @islogical);
            addParameter(ip, 'ax', [], @ishandle);
            parse(ip, varargin{:});
            
            if isempty(ip.Results.ax)                
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
            else
                ax = ip.Results.ax;
                fh = get(ax, 'Parent');
            end
            hold(ax, 'on');
            p = surf(ax, obj.newXPts, obj.newYPts,...
                obj.interpolatedSurface,...
                'FaceColor', 'interp',...
                'FaceAlpha', 0.8,...
                'EdgeColor', 'none',...
                'BackFaceLighting', 'lit',...
                'Tag', 'BoundarySurface');
            if ip.Results.showData
                hold(ax, 'on');
                if strcmp(obj.units, 'microns')
                    xyz = viking2micron(obj.markerLocations, obj.source);
                else
                    xyz = obj.markerLocations;
                end
                scatter3(ax, xyz(:, 1), xyz(:, 2), xyz(:,3), 'fill',...
                    'Tag', 'BoundaryMarker');
            end
            view(ax, 3);
            axis(ax, 'equal');
            if isa(fh, 'matlab.ui.Figure')
                set(fh, 'Renderer', 'painters');
            end
        end

        function addToScene(obj, ax, varargin)
            % ADDTOSCENE
            %
            % Description:
            %   Plot the boundary markers to a scene
            %
            % -------------------------------------------------------------
            assert(ishandle(ax), 'Must input an axes handle');
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'Size', 15, @isnumeric);
            addParameter(ip, 'Color', [0.5 0.5 0.5],...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'Style', '.', @ischar);
            parse(ip, varargin{:});

            if strcmp(obj.units, 'microns')
                xyz = viking2micron(obj.markerLocations, obj.source);
            else
                xyz = obj.markerLocations;
            end
            hold(ax, 'on');
            scatter3(ax, xyz(:,1), xyz(:,2), xyz(:,3),... 
                ip.Results.Size, ip.Results.Color, ip.Results.Style,...
                'Tag', 'BoundaryMarker');
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
            disp('Querying OData...');
			data = readOData([obj.baseURL,...
				'Structures?$filter=TypeID eq ' num2str(obj.TYPEID),... 
				'&$select=ID']);
            value = cat(1, data.value{:});
            markerIDs = vertcat(value.ID);
            xyz = [];
            
            for i = 1:numel(markerIDs)
                data = readOData([obj.baseURL,...
                    'Structures(', num2str(markerIDs(i)), ')',...
                    '/Locations?$select=X,Y,Z']);
                xyz = cat(1, xyz, data.value{:});
            end
            obj.markerLocations = [...
                vertcat(xyz.X),...
                vertcat(xyz.Y),...
                vertcat(xyz.Z)];
			obj.queryDate = datestr(now);
        end   
    end
    
    methods (Static)
        function deleteFromScene(ax)
            % DELETEFROMSCENE
            % 
            % Description:
            %   Delete all objects with tag "BoundaryMarker" from axes
            % Input:
            %   ax      axes handle
            % -------------------------------------------------------------
            assert(ishandle(ax), 'Must input an axes handle');
            delete(findall(ax, 'Tag', 'BoundarySurface'));
            delete(findall(ax, 'Tag', 'BoundaryMarker'));
        end
    end
end
