classdef BinaryImage < sbfsem.ui.FigureView

	properties (Access = private)
		annotations
		boundingBox
		scaleFactor
	end

	properties (SetAccess = private, GetAccess = public)
		frame
	end

	methods
		function obj = BinaryImage(annotations, boundingBox, scaleFactor)
			set(obj.figureHandle, 'Color', 'k');
			set(obj.ax, 'Color', 'k');

			% Add the annotations
			for i = 1:numel(obj.annotations)
				obj.annotations(i).addAnnotation(obj.ax);
			end

			% Set the bounding box to keep axes consistent
			set(obj.ax, 'XLim', boundingBox(1:2),...
				'YLim', boundingBox(3:4));
			axis(obj.ax, 'equal');
			axis(obj.ax, 'off');

			% Capture the plot as an image
			obj.frame = getframe(obj.ax);
			% Convert to binary image for render
			obj.frame = imbinarize(rgb2gray(obj.frame.cdata));
			% Resize image
			if scaleFactor > 0
				F = imresize(F, scaleFactor);
			end
			% Clear out the figure
			delete(fh);
		end
	end
end