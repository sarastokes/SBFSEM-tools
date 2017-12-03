classdef (Abstract) RenderView < sbfsem.ui.FigureView
    
    properties (SetAccess = protected)
        ID
        source
        renderObj
        lightObj
        capObj
        boundingBox
    end
    
    properties (Transient = true, SetAccess = protected)
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
            
            assert(isa(neuron, 'sbfsem.Neuron'), 'Input neuron object');
            
            obj@sbfsem.ui.FigureView(1);
            obj.ID = neuron.ID;
            obj.source = neuron.source;

            set(obj.figureHandle,...
                'Name', ['c', num2str(obj.ID), ' render'],...
                'Color', 'k');
            set(obj.ax, 'Color', 'k');
        end
        
        function update(obj)
            neuron = Neuron(obj.ID, obj.source);
            neuron.setGeometries;
            obj.doRender(neuron.geometries);
        end
    end
    
    methods (Access = protected)
        function createScene(obj, binaryMatrix)
            % Smooth binary images to increase cohesion
            % TODO: apply extra gauss conv to z-axis only?
            smoothedImages = smooth3(binaryMatrix);
            
            % Create the 3D structure
            obj.renderObj = patch(isosurface(smoothedImages),...
                'Parent', obj.ax,...
                'FaceColor', obj.FACECOLOR,...
                'FaceAlpha', obj.FACEALPHA,...
                'EdgeColor', 'none');
            obj.capObj = patch(isosurface(smoothedImages,0),...
                'FaceColor', obj.FACECOLOR,...
                'FaceAlpha', obj.FACEALPHA,...
                'EdgeColor', 'none');
            isonormals(smoothedImages, obj.renderObj);
            
            view(obj.ax, 35, 30);
            
            % Set up the lighting
            obj.lightObj = camlight(obj.CAMANGLE(1), obj.CAMANGLE(2));
            obj.lightObj.Style = 'Local';
            set(obj.renderObj,...
                'FaceLighting', 'gouraud',...
                'SpecularExponent', obj.SPECULAREXP,...
                'SpecularColorReflectance', obj.SPECULARCOLORREFLECTANCE);
            
            % Scale axis to match volume dimensions
            daspect(obj.ax, getDAspectFromOData(obj.source));
            axis(obj.ax, 'equal');
            obj.labelXYZ();
        end
        
        function boundingBox = findBoundingBox(obj)
            allBounds = vertcat(obj.imNodes.localBounds);
            boundingBox = [ min(allBounds(:,1)), max(allBounds(:,2)),... 
                            min(allBounds(:,3)), max(allBounds(:,4))];
            
            if obj.BOUNDINGMARGIN > 0
                boundingBox = boundingBox * (1 + obj.BOUNDINGMARGIN);
            end
        end
        
        function binaryMatrix = padBinaryImages(obj, xy, F)
            % Resize the binary images to xy limits
            binaryMatrix = [];
            for i = 1:numel(F)
                im = F{i};
                if size(im,1) < xy(1)
                    pad = xy(1)-size(im,1);
                    fprintf('Image %u: Added %u to x-axis\n', i, pad);
                    im = padarray(im, [pad, 0], 0, 'pre');
                end
                if size(im,2) < xy(2)
                    pad = xy(2)-size(im,2);
                    fprintf('Image %u: Added %u to y-axis\n', i, pad);
                    im = padarray(im, [0, pad], 0, 'pre');
                end
                binaryMatrix = cat(3, binaryMatrix, im);
            end
        end
    end
end
