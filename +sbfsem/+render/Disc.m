classdef Disc < sbfsem.render.RenderView
%DISC  Create render based on disc annotations
% 
% Constructor: 
%   obj = Disc(neuron, varargin);
%   % Specify a subset of the Z sections
%   obj = Disc(neuron, 'sections', 1:10);
%   % Change the resize factor (inherited from RenderView)
%   obj = Disc(neuron, 'scaleFactor', 0.8);
%
% Properties:
%   All inherited from RenderView
%
%   12Nov2017 - SSP
%
% See also SBFSEM.CORE.DISC, SBFSEM.RENDER.RENDERVIEW
	
	methods
		function obj = Disc(neuron, varargin)
            % DISCRENDER  Create a render figure and object
            obj@sbfsem.render.RenderView(neuron);

            ip = inputParser();
            addParameter(ip, 'sections', [], @isnumeric);
            addParameter(ip, 'scaleFactor', obj.RESIZEFACTOR, @isnumeric);
            parse(ip, varargin{:});

            if isempty(ip.Results.sections)
            	sections = unique(neuron.nodes.Z);
            else
                sections = ip.Results.sections;
            end
            scaleFactor = ip.Results.scaleFactor;

            obj.doRender(neuron.nodes, sections, scaleFactor);
		end
	end

	methods (Access = private)
		function doRender(obj, nodes, sections, scaleFactor)
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

            % Init frames and image size array
            F = cell(0,1);
            xy = zeros(numel(obj.imNodes), 2);

            % Create binary matrix
            for i = 1:numel(obj.imNodes)
            	% Set the bounding box
            	obj.imNodes(i).setBoundingBox(obj.boundingBox);
            	% Binarize and resize
            	F = cat(1, F, obj.imNodes(i).resize(scaleFactor));
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
