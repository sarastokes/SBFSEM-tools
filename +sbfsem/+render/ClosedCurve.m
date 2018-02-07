classdef ClosedCurve < sbfsem.render.RenderView
    % CLOSEDCURVERENDER  
    %
    % Description:
    %   Create a render figure and object
    %
    % Constructor:
    %   obj = sbfsem.render.ClosedCurve(neuron, 'scaleFactor', 1,...
    %                                   'smoothVol', true);
    % Inputs:
    %	neuron 		Neuron object
    % Optional inputs:
    %	scaleFactor 	[1]		used with imresize()
    %   smoothVol       [true]  apply smooth3 before isosurface generation
    %
    % Methods:
    %   obj.setSmoothVol(true)      Set whether to smooth the volume
    %   obj.dae(fname, fpath);      Export to COLLADA .dae
    % 
    % History:
    %   10Nov2017 - SSP
    %   31Jan2018 - SSP - smoothVol input, misc updates and debugging
    %   1Feb2018 - SSP - added exportDAE method
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        binaryMatrix
        scaleFactor
        smoothVol
    end

    methods
        function obj = ClosedCurve(neuron, scaleFactor, smoothVol)
            % CLOSEDCURVE  Constructor
			obj@sbfsem.render.RenderView(neuron);

            if nargin < 3
                obj.smoothVol = true;
            else
                assert(islogical(smoothVol), 'smoothVol is logical');
                obj.smoothVol = smoothVol;
            end

			if nargin < 2
				obj.scaleFactor = 1;
            else
                assert(isnumeric(scaleFactor),...
                    'Scale factor must be numeric');
                obj.scaleFactor = scaleFactor;
			end

            % Get geometries and sort by section
            if isempty(neuron.geometries)
                neuron.getGeometries();
            end
            T = neuron.geometries;
            T = sortrows(T, 'Z');

            % Convert to closed curve
            obj.imNodes = cell(0, 1);
            disp('Converting to closed curve');
            for i = 1:height(T)
                obj.imNodes = cat(1, obj.imNodes,...
                    sbfsem.core.ClosedCurve(T(i,:)));
            end

            % Create the render
			obj.doRender();
		end

        function setSmoothVol(obj, smoothVol)
            % SETSMOOTHVOL  Set whether to use smooth3 on volume
            assert(islogical(smoothVol), 'smoothVol is t/f variable');
            obj.smoothVol = smoothVol;
        end
        
        function dae(obj, fname, fpath)
            % DAE  Export as COLLADA .dae file for Blender
            % 
            % Inputs:
            %   fname       File name
            %   fpath       File path (default = current directory)
            % -------------------------------------------------------------
            
            if isempty(strfind(fname, '.dae'))
                fname = [fname, '.dae'];
            end
            
            if nargin < 3
                fpath = cd;
            end
            
            [vertices, faces] = concatenateMeshes(...
                obj.renderObj.Vertices, obj.renderObj.Faces,...
                obj.capObj.Vertices, obj.capObj.Faces);
            
            savePath = [fpath, filesep, fname];
            
            exportDAE(savePath, vertices, faces);
            disp(['Exported mesh as ', savePath]);
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
            % sections = flipud(unique(arrayfun(@(x) x.Z(1),obj.imNodes,...
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
            	M = obj.padBinaryImages(xy, renderImage);
            else
            	disp('Uniform images, skipping padding');
            	M = [];
            	for i = 1:numel(obj.imNodes)
            		M = cat(3, M, renderImage{i});
            	end
            end
            obj.createScene(M, obj.smoothVol);
            obj.binaryMatrix = M;
        end
	end
end