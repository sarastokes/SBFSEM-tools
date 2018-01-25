classdef BinaryView < handle
% BINARYVIEW  Plots annotation as binary patches
%
% Inputs:
%	annotations		ClosedCurve or Disc objects
% Optional inputs:
%	boundingBox 	[]		[xmin ymin xmax ymax]
%	scaleFactor		[1]		used with imresize();
%
% 15Nov2017 - SSP

	properties (SetAccess = private, GetAccess = public)
		binaryImage
	end

	methods
		function obj = BinaryView(annotations, boundingBox, scaleFactor)

			if nargin < 3
				scaleFactor = 1;
			else
				validateattributes(scaleFactor, {'numeric'},...
					{'numel', 1, 'nonnegative'});
			end
			if nargin < 2
				boundingBox = [];
			else
				validateattributes(boundingBox, {'numeric'},...
                    {'size', [1 4]});
			end

			fh = figure('Color', 'k');
			ax = axes('Parent', fh, 'Color', 'k');
			hold(ax, 'on');

			% Use object's addAnnotation fcn
			for i = 1:numel(annotations)
				annotations(i).addAnnotation(ax);
			end

			% Set the bounding box to keep axes consistent
			if ~isempty(boundingBox)
				set(ax, 'XLim', boundingBox(1:2),...
					'YLim', boundingBox(3:4));
            end
			axis(ax, 'equal');
			axis(ax, 'off');

			% Capture the plot as an image
			obj.binaryImage = getframe(ax);
			% Convert to binary image for render
			obj.binaryImage = imbinarize(rgb2gray(obj.binaryImage.cdata));
			% Resize image
			if scaleFactor ~= 1
				obj.binaryImage = imresize(obj.binaryImage, scaleFactor);
			end
			% Clear out the figure
			hold(ax, 'off');
			delete(fh);
		end
	end
end