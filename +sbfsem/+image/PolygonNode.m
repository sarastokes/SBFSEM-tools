classdef PolygonNode < sbfsem.image.Node
    
    properties (SetAccess = private)
        cutouts
    end
    
    properties (Transient = true)
        binaryImage
    end
    
    methods
        function obj = PolygonNode(xy, label)
            if iscell(xy)
                if numel(xy) > 1
                    obj.imData = xy{1};
                    obj.cutouts = xy{2:end};
                else
                    obj.imData = xy{:};
                end
            else
                obj.imData = xy;
            end
            
            if nargin == 2
                obj.name = label;
            end
            
            obj.binaryImage = obj.binarize();
        end
        
        function ax = show(obj, ax)
			if nargin == 2
				validateattributes(ax, {'handle'}, {});
				fh = ax.Parent;
			else
				fh = figure();
				ax = axes('Parent', fh);
            end		
            imshow(ax, obj.binaryImage);           
        end
        
        function F = binarize(obj, visualize)
            if nargin < 2
                visualize = false;
            end
            % Create a new figure/axis
            fh = figure('Color', 'k');
            ax = axes('Parent', fh, 'Color', 'k');
            % Plot the closed curve as a polygon
            patch(obj.imData(:,1), obj.imData(:,2), 'w', 'Parent', ax);
            axis(ax, 'off');
            % Convert the plot to an image
            F = getframe(ax);
            % Make into a binary image for processing
            F = imbinarize(rgb2gray(F.cdata));
            % Clear out the figure
            if ~visualize
                delete(fh);
            end
        end
    end
end
