classdef ClosedCurveRender < sbfsem.render.RenderView
	
	methods
		function obj = ClosedCurveRender(neuron, updateGeometries)
            % CLOSEDCURVERENDER  Create a render figure and object
            % Inputs:
            %	neuron 		Neuron object
            % Optional:
            %	updateGeometries 	[false]		pull OData
            %
            % 10Nov2017 - SSP
			obj@sbfsem.render.RenderView(neuron);

			if nargin < 2
				updateGeometries = false;
			else
				assert(islogical(updateGeometries),...
					'updateGeometries is t/f');
			end

			if updateGeometries || isempty(neuron.geometries)
				neuron.setGeometries();
			end

			obj.doRender(neuron.geometries);
		end
	end

	methods (Access = private)
		function doRender(obj, geometries)

			% Convert to ClosedCurve
			obj.imNodes = cell(0,1);
			disp('Converting to ClosedCurve');
			for i = 1:height(geometries)
				obj.imNodes = cat(1, obj.imNodes,...
					sbfsem.core.ClosedCurve(geometries.Curve{i}));
			end

			% Find XY limits to use as bounding box
			fprintf('Calculating bounding box: ');
			obj.boundingBox = obj.findBoundingBox();
            fprintf('= (%u  %u), (%u  %u)\n', round(obj.boundingBox));

            F = cell(0,1);
            xy = zeros(numel(obj.imNodes), 2);
            for i = 1:numel(obj.imNodes)
            	% Set the bounding box
            	obj.imNodes(i).setBoundingBox(obj.boundingBox);
            	% Binarize and resize
            	F = cat(1, F, obj.imNodes(i).resize(obj.RESIZEFACTOR));
            	% Kepp a running count on image sizes
            	xy(i,:) = size(obj.imNodes(i).binaryImage);
            end

            % Determine whether images need to be padded
            if numel(unique(xy)) > 2
            	% Find the maximum for X and Y dimensions
            	xy = max(xy);
            	binaryMatrix = obj.padBinaryImages(xy, F);
            else
            	disp('Uniform images, skipping padding');
            	binaryMatrix = [];
            	for i = 1:numel(obj.imNodes)
            		binaryMatrix = cat(3, binaryMatrix, F{i});
            	end
            end
            obj.createScene(binaryMatrix);
        end
	end
end