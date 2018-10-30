classdef (Abstract) RenderView < sbfsem.ui.FigureView
    % RENDERVIEW
    %
    % Description:
    %   Abstract class for volume renders
    %
    % Constructor:
    %   obj = sbfsem.render.RenderView(neuron)
    %
    % Protected properties:
    %   ID              Neuron ID
    %   source          Volume name
    %   renderObj       Render object (patch)
    %   capObj          Isocaps object
    %   boundingBox     XY limits around render
    %   imNodes         Annotations (sbfsem.builtin.ClosedCurve/Disc)
    %
    % Constant properties:
    %   Patch defaults, cam angle, bounding margin (0)
    %
    % Public methods:
    %   bbox = obj.findBoudningBox(obj);
    %   obj.update();
    % Protected methods:
    %   obj.createScene(binaryMatrix);
    % Static methods:
    %   obj.padBinaryImages();
    %   
    % See also:
    %   SBFSEM.RENDER.CLOSEDCURVE, SBFSEM.CORE.CLOSEDCURVE
    %
    % History:
    %   15Nov2017 - SSP
    %   21Jan2018 - xyz scaling, isocaps, docs
    % ---------------------------------------------------------------------
    
    properties (SetAccess = protected)
        ID
        source
        renderObj
        capObj
        boundingBox
        imNodes
    end
    
    properties (Constant = true, Hidden = true, Access = protected)
        FACEALPHA = 1;
        FACECOLOR = [0.7, 0.7, 0.7];
        BOUNDINGMARGIN = 0;
        RESIZEFACTOR = 0.5;

        SPECULAREXP = 50;
        SPECULARCOLORREFLECTANCE = 0;
        CAMANGLE = [90, 90];
    end
    
    methods
        function obj = RenderView(neuron)
            % RENDERVIEW  Create a render figure and object
            % Inputs:
            %	neuron 		        Neuron object
            %
            % 10Nov2017 - SSP
            
            assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
                'Input Structure object');
            
            obj@sbfsem.ui.FigureView(1);
            obj.ID = neuron.ID;
            obj.source = neuron.source;

            set(obj.figureHandle,...
                'Name', ['c', num2str(obj.ID), ' render'],...
                'Color', 'k');
            set(obj.ax, 'Color', 'k');
        end
        
        function update(obj)
            % UPDATE
            neuron = Neuron(obj.ID, obj.source);
            neuron.setGeometries();
            obj.doRender(neuron.geometries);
        end

        function set(obj, propName, propValue)
            % SET  Quicky set patch properties
            % Similar to clicking patch and using set(gco,...)
            % ------------------------------------------------------------
            try
                set(obj.renderObj, propName, propValue);
                set(obj.capObj, propName, propValue);
            catch
                warning(' Unknown property: %s', propName);
            end
        end
    end
    
    methods (Access = protected)
        function createScene(obj, binaryMatrix, smoothVol)
            % CREATESCENE  Setup figure for volume render of binary matrix
            % Inputs:
            %   binaryMatrix   X by Y by Z 3D logical matrix
            % -------------------------------------------------------------
            if nargin < 3
                smoothVol = true;
            else
                assert(islogical(smoothVol), 'smoothVol is t/f');
            end
                       
            % Smooth binary images to increase cohesion
            % TODO: apply extra gauss conv to z-axis only?
            if smoothVol
                disp('RENDERVIEW: Smoothing volume');
                smoothedImages = smooth3(binaryMatrix);
            end
            
            % Create the 3D structure
            obj.renderObj = patch(isosurface(smoothedImages),...
                'Parent', obj.ax,...
                'FaceColor', obj.FACECOLOR,...
                'FaceAlpha', obj.FACEALPHA,...
                'EdgeColor', 'none',...
                'FaceLighting', 'gouraud',...
                'SpecularExponent', obj.SPECULAREXP,...
                'SpecularColorReflectance', obj.SPECULARCOLORREFLECTANCE);
            % Ensure 3D structure water-tight
            obj.capObj = patch(isocaps(smoothedImages),...
                'FaceColor', obj.FACECOLOR,...
                'FaceAlpha', obj.FACEALPHA,...
                'EdgeColor', 'none',...
                'FaceLighting', 'gouraud',...
                'SpecularExponent', obj.SPECULAREXP,...
                'SpecularColorReflectance', obj.SPECULARCOLORREFLECTANCE);
            % Normals
            isonormals(smoothedImages, obj.renderObj);
            
            % Set up the lighting
            lightangle(45,30);
            lightangle(225,30);
            
            % Scale axis to match volume dimensions
            axis(obj.ax, 'equal');
            obj.labelXYZ();
            view(obj.ax, 3);
        end
        
        function boundingBox = findBoundingBox(obj)
            % FINDBOUNDINGBOX  Get the render bounding box
            allBounds = vertcat(obj.imNodes.localBounds);
            boundingBox = [ min(allBounds(:,1)), max(allBounds(:,2)),... 
                            min(allBounds(:,3)), max(allBounds(:,4))];            
            if obj.BOUNDINGMARGIN > 0
                disp(['Bounding margin: ', num2str(obj.BOUNDINGMARGIN)]);
                boundingBox = boundingBox * (1 + obj.BOUNDINGMARGIN);
            end
        end
    end
    methods (Static)
        function binaryMatrix = padBinaryImages(xy, F)
            % PADBINARYIMAGES  Resize the binary images to xy limits
            binaryMatrix = [];
            for i = 1:numel(F)
                im = F{i};
                if size(im,1) < xy(1)
                    pad = xy(1)-size(im,1);
                    im = padarray(im, [pad, 0], 0, 'pre');
                end
                if size(im,2) < xy(2)
                    pad = xy(2)-size(im,2);
                    im = padarray(im, [0, pad], 0, 'pre');
                end
                binaryMatrix = cat(3, binaryMatrix, im);
            end
            fprintf('\n');
        end
    end
end
