classdef ClosedCurve < sbfsem.render.RenderView
    % CLOSEDCURVERENDER  Create a render figure and object
    %
    % Inputs:
    %	neuron 		Neuron object
    % Optional inputs:
    %	scaleFactor 	[1]		used with imresize()
    %
    %
    % 10Nov2017 - SSP
    
    properties (SetAccess = private)
        binaryMatrix
        scaleFactor
    end

    methods
        function obj = ClosedCurve(neuron, scaleFactor)
			obj@sbfsem.render.RenderView(neuron);

			if nargin < 2
				obj.scaleFactor = 1;
            else
                assert(isnumeric(scaleFactor),...
                    'Scale factor must be numeric');
                obj.scaleFactor = scaleFactor;
			end

			if isempty(neuron.geometries)
				neuron.getGeometries();
			end

            % Get geometries and sort by section
            T = neuron.geometries;
            T = sortrows(T, 'Z');

            % Convert to closed curve
            obj.imNodes = cell(0, 1);
            disp('Converting to closed curve');
            for i = 1:height(T)
                obj.imNodes = cat(1, obj.imNodes,...
                    sbfsem.core.ClosedCurve(T(i,:)));
            end

			obj.doRender();
		end
	end

	methods (Access = private)
		function doRender(obj)
            % DORENDER  Creates binary images, then the 3d volume

    		% Find XY limits to use as bounding box
    		fprintf('Calculating bounding box: ');
    		% obj.boundingBox = obj.findBoundingBox();
            obj.boundingBox = groupBoundingBox(obj.imNodes);
            fprintf('= (%u  %u), (%u  %u)\n', round(obj.boundingBox));

            % Determine the number of sections for entire render
            % sections = flipud(unique(arrayfun(@(x) x.Z(1), obj.imNodes,...
            %    'UniformOutput', false)));
            sections = vertcat(obj.imNodes.Z);
            sections = flipud(unique(sections(:,1)));

            fprintf('Rendering %u annotations across %u sections\n',...
                numel(obj.imNodes), numel(sections));

            renderImage = cell(0,1);
            xy = zeros(numel(obj.imNodes), 2);
            for i = 1:numel(sections)
                sectionNodes = obj.imNodes(bsxfun(@eq,...
                    arrayfun(@(x) x.Z(1), obj.imNodes), sections(i)));
                % Create the binary image
                im = sbfsem.render.BinaryView(sectionNodes,...
                    obj.boundingBox, obj.scaleFactor);
                renderImage = cat(1, renderImage, im.binaryImage);
                % Keep a running count on image sizes
                xy(i,:) = size(im.binaryImage);
            end

            % Determine whether images need to be padded
            if numel(unique(xy)) > 2
            	% Find the maximum for X and Y dimensions
            	xy = max(xy);
            	binaryMatrix = obj.padBinaryImages(xy, renderImage);
            else
            	disp('Uniform images, skipping padding');
            	binaryMatrix = [];
            	for i = 1:numel(obj.imNodes)
            		binaryMatrix = cat(3, binaryMatrix, renderImage{i});
            	end
            end
            obj.createScene(binaryMatrix);
            obj.binaryMatrix = binaryMatrix;
        end
	end
end