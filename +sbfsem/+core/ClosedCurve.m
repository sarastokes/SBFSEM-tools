classdef ClosedCurve < sbfsem.core.Annotation
	%
	%	Inputs:
	%		xy				Cell of 2xN xy coordinates (um)
	%		Z 				Section number
	%
	%	Properties:
	%		outline 		Primary CC structure
	%		cutouts 		Cutouts inside outline
	%		localBounds 	Bounding box for object
	%	Inherited properties:
	%		binaryImage 	Logical image for render
	%		boundingBox 	XY limits for full render
	%
	%	Methods:
	%		F = binarize(obj)
	%	Inherited methods:
	%		F = resize(obj, scaleFactor)
	%		setBoundingBox(boundingBox)
	%
	%	9Nov2017 - SSP
    
    properties (SetAccess = private, GetAccess = public)
        outline
        cutouts = cell(0,1);
    end

    properties (Dependent = true, Hidden = true)
    	localBounds
    end
    
    methods
        function obj = ClosedCurve(xy, Z, parentID)
        	% CLOSEDCURVE
        	%	Inputs:
        	%		xy 		   Cell/table of 2xN coordinates
            %   Optional:    (if xy isn't a table row)
            %       Z           Section number
            %       parentID    neuron ID

            if nargin > 2
                obj.parentID = parentID;
            end

            if nargin > 1 && isnumeric(Z)
                obj.Z = Z;
            else
                obj.Z = [];
            end
            
            if istable(xy)
                curvePts = xy.Curve{:};
                obj.Z = xy.Z;
                obj.parentID = xy.ParentID;
            else
                curvePts = xy;
            end
            
            % Parse the geometry
            if iscell(curvePts)
                if numel(curvePts) > 1
                    obj.outline = curvePts{1};
                    % Save the cutouts separately
                    for i = 2:numel(curvePts)
                        obj.cutouts = cat(1, obj.cutouts, curvePts{i});
                    end
                else
                    obj.outline = curvePts{:};
                end
            end

            if iscell(obj.outline)
                obj.outline = obj.outline{:};
            end
        end

        function localBounds = get.localBounds(obj)
        	localBounds = [	min(obj.outline(:,1)),...
        					max(obj.outline(:,1)),...
        					min(obj.outline(:,2)),...
        					max(obj.outline(:,2))];
		end

        function append(closedcurve)
            assert(isa(closedcurve, 'sbfsem.core.ClosedCurve'),...
                'Input a ClosedCurve object');
            if closedcurve.Z ~= obj.Z
                disp('Mismatch in Z values, not added');
                return;
            end
        end

        function F = binarize(obj, varargin)  
        	% BINARIZE  Convert to logical image and create frame
            % Inputs:
            %   renderCutouts     [true]    false for primary CC only
            %   axHandle          []        add to existing image    
            %   scaleFactor       0         factor to resize image
            % Outputs:
            %   F               binary image     
            if nargin < 2
                scaleFactor = 0;
            end

            fh = figure('Color', 'k');
            ax = axes('Parent', fh, 'Color', 'k');

            obj.addAnnotation(ax);

            % Set the bounding box to keep axes consistent
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
            % Resize image
            if scaleFactor > 0
                F = imresize(F, scaleFactor);
            end
            % Save to object
            obj.binaryImage = F;
            % Clear out the figure
            delete(fh);           
        end

        function addAnnotation(obj, ax)
            % ADDANNOTATION  Appends binary to existing frame
            % Inputs:
            %   ax      axes handle

            % Plot the outlines
            patch(obj.outline(:,1), obj.outline(:,2),...
                'w', 'Parent', ax);
            if ~isempty(obj.cutouts)
                for i = 1:numel(obj.cutouts)
                    curvePoints = obj.cutouts{i};
                    % Hack fix later
                    if nnz(isnan(curvePoints(1,:))) > 0
                        curvePoints(1,:) = curvePoints(end,:);
                    end
                    patch(curvePoints(:,1), curvePoints(:,2),...
                        'k', 'Parent', ax);
                end
            end
        end

        function F = resize(obj, scaleFactor, varargin)
            % RESIZE  Resample the binary image
            % Inputs:
            %	scaleFactor 		resize by x
            % Optional inputs:
            %   see obj.binarize
            
         	F = resize@sbfsem.core.Annotation(obj, scaleFactor, varargin{:});
            obj.binaryImage = F;
        end
    end
end