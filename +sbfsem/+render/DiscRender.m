classdef DiscRender < sbfsem.render.RenderView
	
	methods
		function obj = DiscRender(neuron, sections)
            % DISCRENDER  Create a render figure and object
            obj@sbfsem.render.RenderView(neuron);

            if nargin < 2
            	sections = unique(neuron.nodes.Z);
            end
            obj.doRender(neuron.nodes, sections);
		end
	end

	methods (Access = private)
		function doRender(obj, nodes, sections)
			obj.imNodes = cell(0,1);
			for i = 1:numel(sections)
				sectionRows = nodes.Z == sections(i);
				obj.imNodes = cat(1, obj.imNodes,...
					sbfsem.core.Disc(nodes(sectionRows,:)));
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
