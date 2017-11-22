classdef (Abstract) Annotation < sbfsem.core.EntityType
    % ANNOTATION  Prepares a single annotation for 3D render

    properties (SetAccess = protected, GetAccess = public)
        Z
        parentID
    end

	properties (Transient = true, SetAccess = protected)
		boundingBox = [];
		binaryImage = [];
	end
    
	methods
		function obj = Annotation()
            % Do nothing, leave to subclasses
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

		function F = resize(obj, scaleFactor, varargin)
            % RESIZE  Resample the binary image
            % Inputs:
            %	scaleFactor 		resize by x
            
            % Rerun binarize to prevent multiple call issues
            obj.binarize(varargin{:});
            % Resize the image
            obj.binaryImage = imresize(obj.binaryImage, scaleFactor);
            % Set output if needed
            if nargout == 1
                F = obj.binaryImage;
            end
        end
	end
end