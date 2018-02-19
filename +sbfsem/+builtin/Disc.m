classdef Disc < sbfsem.core.Annotation
	%
	% 	Inputs:
	%		xy 		xy coordinates OR table rows
	%		radius	radii (um)
	%	
	%	Properties
	%		R 		Radii (um)
	%		X 		X coordinates (um)
	%		Y 		Y coordinates (um)
	%	Inherited properties:
	%		binaryImage 	Logical image for render
	%		boundingBox 	XY limits for full render
	%
	%	Methods
	%		F = binarize(obj)
	%		append(Disc)
	%	Inherited methods:
	%		F = resize(obj, scaleFactor)
	%		setBoundingBox(boundingBox)
	%
	%	12Nov2017 - SSP
	%
	% See also SBFSEM.RENDER.DISC, SBFSEM.CORE.ANNOTATION
	
	properties (SetAccess = private, GetAccess = public)
		R
		X
		Y
	end

	properties (Dependent = true, Hidden = true)
		localBounds
	end

	methods
		function obj = Disc(xy, radius)
			if istable(xy)
				xyz = xy.XYZum;
				obj.X = xyz(:,1);
				obj.Y = xyz(:,2);
				if nargin < 2
					obj.R = xy.Rum;
				end
			else
				obj.X = xy(:,1);
				obj.Y = xy(:,2);
				obj.R = radius;
			end
		end

		function localBounds = get.localBounds(obj)
			localBounds = [	min(obj.X-obj.R),...
							max(obj.X+obj.R),...
							min(obj.Y-obj.R),...
							max(obj.Y+obj.R)];
		end

		function binarize(obj, visualize)
			if nargin < 2
				visualize = false;
			end

			fh = figure('Color', 'k');
			ax = axes('Parent', fh, 'Color', 'k');
			hold(ax, 'on');
			% Add all the discs as ellipses
			for i = 1:numel(obj.R)
				rectangle(ax,... 
					'Position', [obj.X(i)-obj.R(i), obj.Y(i)-obj.R(i), 2*obj.R(i), 2*obj.R(i)],...
					'EdgeColor', 'w',...
					'FaceColor', 'w',...
					'Curvature', 1);
			end

			% Set the bounding box to keep the axes consistent
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
			if ~visualize
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