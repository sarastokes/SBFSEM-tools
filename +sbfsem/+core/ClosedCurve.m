classdef ClosedCurve < sbfsem.core.Annotation
    % CLOSEDCURVE
    %
    % Description:
    %   Individual closed curve annotations and cutouts
    %
    %	Inputs:
    %		xy				Cell of 2xN xy coordinates (um)
    %		Z 				Vector [Section number, microns]
    %
    % Properties:
    %		outline 		Primary CC structure
    %		cutouts 		Cutouts inside outline
    % Dependent properties:
    %		localBounds 	Bounding box for object
    % Inherited properties:
    %		binaryImage 	Logical image for render
    %		boundingBox 	XY limits for full render
    %
    % Methods:
    %		F = binarize(obj)
    %       trace(obj, varargin);
    %       addAnnotation(obj, ax);
    %       append(obj, ClosedCurve);
    %       resize(obj, scaleFactor, varargin);
    %
    % History:
    %	9Nov2017 - SSP
    %   30Dec2017 - SSP - catmull rom splines, trace method
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private, GetAccess = public)
        outline
        cutouts = cell(0,1);    % Cell array of cutouts
    end
    
    properties (Dependent = true, Hidden = true)
        localBounds             % Bounding box around annotation
    end
    
    methods
        function obj = ClosedCurve(data)
            % CLOSEDCURVE
            %	Inputs:
            %		data        row of geometry table
            
            if isa(data, 'Neuron')
                data = data.geometries;
            end
            
            curvePts = data.Curve{:};
            obj.Z = [data.Z, data.Zum];
            obj.parentID = data.ParentID;
            
            % Parse the geometry
            if iscell(curvePts)
                if numel(curvePts) > 1
                    obj.outline = curvePts{1};
                    % Save the cutouts separately
                    for i = 2:numel(curvePts)
                        obj.cutouts = cat(1, obj.cutouts, curvePts{i});
                    end
                else
                    obj.outline = curvePts{:};
                end
            end
            
            if iscell(obj.outline)
                obj.outline = obj.outline{:};
            end
        end
        
        function append(closedcurve)
            assert(isa(closedcurve, 'sbfsem.core.ClosedCurve'),...
                'Input a ClosedCurve object');
            if closedcurve.Z ~= obj.Z
                disp('Mismatch in Z values, not added');
                return;
            end
        end
        
        function localBounds = get.localBounds(obj)
            localBounds = [	min(obj.outline(:,1)),...
                max(obj.outline(:,1)),...
                min(obj.outline(:,2)),...
                max(obj.outline(:,2))];
        end
        
        function F = binarize(obj, varargin)
            % BINARIZE  Convert to logical image and create frame
            %
            % Inputs:
            %   renderCutouts     [true]    false for primary CC only
            %   axHandle          []        add to existing image
            %   scaleFactor       0         factor to resize image
            %
            % Outputs:
            %   F               binary image
            
            if nargin < 2
                scaleFactor = 0;
            end
            
            fh = figure('Color', 'k');
            ax = axes('Parent', fh, 'Color', 'k');
            
            obj.addAnnotation(ax);
            
            % Set the bounding box to keep axes consistent
            if ~isempty(obj.boundingBox)
                xlim(ax, obj.boundingBox(1:2));
                ylim(ax, obj.boundingBox(3:4));
            end
            axis(ax, 'equal');
            axis(ax, 'off');
            % Capture the plot as an image
            F = getframe(ax);
            % Convert to binary image for render
            F = imbinarize(rgb2gray(F.cdata));
            % Resize image
            if scaleFactor > 0
                F = imresize(F, scaleFactor);
            end
            % Save to object
            obj.binaryImage = F;
            % Clear out the figure
            delete(fh);
        end
        
        function trace(obj, varargin)
            % TRACE  Plot the splines thru the control points
            %
            % Optional key/value inputs:
            %   ax          [new]       handle to existing axis
            %   dim         [3]         plot dimensions
            %   facecolor   'none'      patch fill color (rgb, 'none')
            %   edgecolor   [0,0,0]     patch edge color (rgb, 'none')
            %   linewidth   [1]         plot linewidth
            %   tag         [parentID]   identifier for patch obj (char)
            %
            % 30Dec2017 - SSP
            
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'dim', 3, @(x) ismember(x, [2 3]));
            addParameter(ip, 'EdgeColor', [0,0,0],...
                @(x) ischar(x) || isvector(x));
            addParameter(ip, 'FaceColor', 'none',...
                @(x) ischar(x) || isvector(x));
            addParameter(ip, 'FaceAlpha', 1,...
                @(x) validateattributes(x, {'numeric'}, {'<',1, '>',0}));
            addParameter(ip, 'EdgeAlpha', 1,...
                @(x) validateattributes(x, {'numeric'}, {'<',1, '>',0}));
            addParameter(ip, 'LineWidth', 1, @isnumeric);
            addParameter(ip, 'Tag', ['c', num2str(obj.parentID)], @ischar);
            parse(ip, varargin{:});
            
            if isempty(ip.Results.ax)
                fh = figure('Name', 'ClosedCurve Outline');
                ax = axes('Parent', fh);
                axis(ax, 'equal');
            else
                ax = ip.Results.ax;
                hold(ax, 'on');
            end
            
            % Convert control points to a catmull-rom spline
            [x, y] = obj.getSpline(obj.outline(:,1), obj.outline(:,2));
            
            % Plot as face/vertex patch 
            if ip.Results.dim == 2
                h = patch(x, y, 'Parent', ax);
            else
                h = patch('XData', x, 'YData', y,...
                    'ZData', obj.Z(2) + zeros(size(x)),...
                    'Parent', ax);
            end
            
            set(h,...
                'FaceColor', ip.Results.FaceColor,...
                'FaceAlpha', ip.Results.FaceAlpha,...
                'EdgeColor', ip.Results.EdgeColor,...
                'EdgeAlpha', ip.Results.EdgeAlpha,...
                'LineWidth', ip.Results.LineWidth,...
                'FaceLighting', 'none',...
                'EdgeLighting', 'none',...
                'Tag', ip.Results.Tag);
        end
        
        function addAnnotation(obj, ax)
            % ADDANNOTATION  Appends binary to existing frame
            %
            % Inputs:
            %   ax      axes handle
            
            % Convert to catmull rom spline
            [x, y] = obj.getSpline(...
                obj.outline(:,1), obj.outline(:,2));
            % Plot the outlines in white
            patch(x, y, 'w', 'Parent', ax);
            if ~isempty(obj.cutouts)
                for i = 1:numel(obj.cutouts)
                    curvePoints = obj.cutouts{i};
                    % Hack fix later
                    if nnz(isnan(curvePoints(1,:))) > 0
                        curvePoints(1,:) = curvePoints(end,:);
                    end
                    % Convert to a catmull rom spline
                    [x, y] = obj.getSpline(...
                        curvePoints(:, 1), curvePoints(:, 2));
                    % Plot the cutouts in black
                    patch(x, y, 'k', 'Parent', ax);
                end
            end
        end
        
        function F = resize(obj, scaleFactor, varargin)
            % RESIZE  Resample the binary image
            %
            % Inputs:
            %	scaleFactor 		resize by x
            %
            % Optional inputs:
            %   see obj.binarize
            
            F = resize@sbfsem.core.Annotation(...
                obj, scaleFactor, varargin{:});
            obj.binaryImage = F;
        end
    end
    
    methods (Static)
        function [x, y] = getSpline(x0, y0)
            % GETSPLINE  Pad x,y vectors for catmull-rom spline
            x0 = x0(:);
            y0 = y0(:);
            x0 = cat(1, x0, x0(1:3));
            y0 = cat(1, y0, y0(1:3));
            [x, y] = catmullRomSpline(x0, y0);
        end
    end
end