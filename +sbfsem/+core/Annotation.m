classdef Annotation < sbfsem.core.EntityType
	
	properties (Transient = true, SetAccess = protected)
		boundingBox = [];
		binaryImage = [];
	end
    
	methods
		function obj = Annotation()
			% Do nothing
		end
	end

	methods
        function setBoundingBox(obj, boundingBox)
        	% SETBOUNDINGBOX  XY limits for full render
        	%
        	%	Inputs:
        	%		boundingBox 	[x1 x2 y1 y2]
        	%
        	validateattributes(boundingBox, {'double'},...
        		{'size', [1,4]});
        	obj.boundingBox = boundingBox;
		end

		function F = resize(obj, scaleFactor)
            % RESIZE  Resample the binary image
            % Inputs:
            %	scaleFactor 		resize by x
            
            % Rerun binarize to prevent multiple call issues
            obj.binarize();
            % Resize the image
            obj.binaryImage = imresize(obj.binaryImage, scaleFactor);
            % Set output if needed
            if nargout == 1
                F = obj.binaryImage;
            end
        end
	end
end