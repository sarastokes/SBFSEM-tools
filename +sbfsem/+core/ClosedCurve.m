classdef ClosedCurve < sbfsem.core.Annotation
	%
	%	Inputs:
	%		xy				Cell of 2xN xy coordinates (um)
	%		Z 				Section number
	%
	%	Properties:
	%		outline 		Primary CC structure
	%		cutouts 		Cutouts inside outline
	%		localBounds 	Bounding box for object
	%	Inherited properties:
	%		binaryImage 	Logical image for render
	%		boundingBox 	XY limits for full render
	%
	%	Methods:
	%		F = binarize(obj)
	%	Inherited methods:
	%		F = resize(obj, scaleFactor)
	%		setBoundingBox(boundingBox)
	%
	%	9Nov2017 - SSP
    
    properties (SetAccess = private, GetAccess = public)
        outline
        cutouts = cell(0,1);
    end

    properties (Dependent = true, Hidden = true)
    	localBounds
    end
    
    methods
        function obj = ClosedCurve(xy)
        	% CLOSEDCURVE
        	%	Inputs:
        	%		xy 		Cell/table of 2xN coordinates
            if istable(xy)
                xy = xy.Curve;
            end
            
            if iscell(xy)
                if numel(xy) > 1
                    % Save the outline separate from cutouts
                    obj.outline = xy{1};
                    for i = 2:numel(xy)
                        obj.cutouts = cat(1, obj.cutouts, xy{i});
                    end
                else
                    obj.outline = xy{:};
                end
            end
        end

        function localBounds = get.localBounds(obj)
        	localBounds = [	min(obj.outline(:,1)),...
        					max(obj.outline(:,1)),...
        					min(obj.outline(:,2)),...
        					max(obj.outline(:,2))];
		end

        function F = binarize(obj, varargin)  
        	% BINARIZE  Convert to logical image          
            ip = inputParser();
            addParameter(ip, 'renderCutouts', true, @islogical);
            addParameter(ip, 'visualize', false, @islogical);
            parse(ip, varargin{:});         
            
            fh = figure('Color', 'k');
            ax = axes('Parent', fh, 'Color', 'k');
            % Plot the closed curve as a polygon
            patch(obj.outline(:,1), obj.outline(:,2),...
                'w', 'Parent', ax);
            if ~isempty(obj.cutouts) && ip.Results.renderCutouts
                for i = 1:numel(obj.cutouts)
                    curvePoints = obj.cutouts{i};
                    % Hack fix later
                    if nnz(isnan(curvePoints(1,:))) > 0
                        curvePoints(1,:) = curvePoints(end,:);
                    end
                    patch(curvePoints(:,1), curvePoints(:,2),...
                        'k', 'Parent', ax);
                end
            end

            % Set the bounding box to keep axes consistent
            if ~isempty(obj.boundingBox)
            	set(ax, 'XLim', obj.boundingBox(1:2),...
            		'YLim', obj.boundingBox(3:4));
            end
            axis(ax, 'equal');
            axis(ax, 'off');
            % Capture the plot as an image
            F = getframe(ax);
            % Convert to binary image for render
            F = imbinarize(rgb2gray(F.cdata));
            % Save to object
            obj.binaryImage = F;
            % Clear out the figure
            if ~ip.Results.visualize
                delete(fh);
            end
        end

        function F = resize(obj, scaleFactor)
            % RESIZE  Resample the binary image
            % Inputs:
            %	scaleFactor 		resize by x
            
         	F = resize@sbfsem.core.Annotation(obj, scaleFactor);
            obj.binaryImage = F;
        end
    end
end