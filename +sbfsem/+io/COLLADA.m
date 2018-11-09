classdef COLLADA < handle
    % COLLADA
    %
    % Description:
    %   Export renders as .dae files for use in programs like Blender
    %
    % Constructor:
    %   obj = sbfsem.io.COLLADA(hObj, fName, reduceFac)
    %
    % Inputs:
    %   hObj        Neuron or axes handle to export as .dae file
    % Optional inputs:
    %   fName       File name (and path) to save
    %   reduceFac   Percent of faces to retain when exporting
    %
    % Notes:
    %   Exporting an entire scene (all renders in axes) requires each
    %   individual render to have it's own Tag. SBFSEM-tools creates these
    %   automatically - if you're adding things manually, make sure they
    %   have some sort of unique tag (doesn't really matter what).
    %
    % Work in progress! Pulling all the .dae functions together, mostly for
    % consistency and testing. For now, there's a lot of code repetition..
    %
    % History:
    %   12Apr2018 - SSP - pulled functions together into one class
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        fName
        reduceFac
        hObj
    end
    
    methods
        function obj = COLLADA(hObj, fName, reduceFac)
            % COLLADA  Constructor
            
            switch class(hObj)
                case {'sbfsem.core.StructureAPI', 'matlab.graphics.axis.Axes'}
                    obj.hObj = hObj;
                otherwise
                    error('SBFSEM:IO:COLLADA:InvalidInput',...
                        'Must provide Neuron object or axes handle');
            end
            
            if nargin == 2
                obj.setPath(fName)
            end
            
            if nargin < 3
                obj.reduceFac = 1;
            else
                obj.setReduction(reduceFac);
            end            
        end
        
        function export(obj, fName)
            if nargin == 2
                obj.setPath(fName);
            elseif isempty(obj.fName)
                obj.fName = uiputfile();
            end
            
            switch class(obj.hObj)
                case 'sbfsem.core.StructureAPI'
                    if isempty(obj.hObj.model)
                        error('SBFSEM:IO:COLLADA:InvalidInput',...
                            'No model - use Neuron\build first');
                    elseif isnumeric(obj.hObj.model)
                        % Volume render
                    elseif isa(obj.hObj.model, 'sbfsem.builtin.ClosedCurve')
                        % Volume render
                    end
                    obj.model.dae();
                case 'matlab.graphics.axis.Axes'
                    obj.exportScene();
            end
        end
        
        function setReduction(obj, reduceFac)
            % SETREDUCTION  Set reduction factor (% faces to retain)
            assert(reduceFac > 0 & reduceFac < 1,...
                'reduceFac should be 0-1');
            obj.reduceFac = reduceFac;
        end
        
        function setPath(obj, fName)
            % SETPATH  Set the save directory and name
            if nargin == 1
                obj.fName = uiputfile();
                return;
            end
            
            % If there are no fileseps, it's just a filename
            if ~mycontains(fName, filesep)
                fPath = uigetdir();
                if isempty(fPath)
                    % Leave if user presses 'Cancel'
                    return
                else
                    fName = [fPath, filesep, fName];
                end
            end
            
            % Check for correct file extension
            if strcmp(fName(end-2:end), '.dae')
                fName = [fName, '.dae'];
            end
            obj.fName = fName;
            fprintf('Saving to %s\n', obj.fName);
        end
    end
    
    methods (Access = private)
        function exportScene(obj)
            axHandle = obj.hObj;
            % TODO: convert any existing lines/surfaces
            allPatches = findall(axHandle, 'Type', 'patch');
            
            % Get the unique tags
            graphNames = unique(arrayfun(@(x) get(x, 'Tag'),...
                allPatches, 'UniformOutput', false));
            fprintf('Saving meshes...')
            disp(graphNames)
            
            allFV = containers.Map();
            % Condense each unique tag into a single mesh
            for i = 1:numel(graphNames)
                patches = findall(axHandle, 'Tag', graphNames{i});
                F = arrayfun(@(x) get(x, 'Faces'), patches,...
                    'UniformOutput', false);
                V = arrayfun(@(x) get(x, 'Vertices'), patches,...
                    'UniformOutput', false);
                % Create into a single faces/vertices struct
                FV = struct(...
                    'faces', vertcat(F{:}),...
                    'vertices', vertcat(V{:}));
                % FV = concatenateMeshes(FV);
                allFV(graphNames{i}) = FV;
            end
            
            % Create the COLLADA document
            DOM = com.mathworks.xml.XMLUtils.createDocument('COLLADA');
            rootNode = DOM.getDocumentElement;

            rootNode.setAttribute(...
                'xmlns','http://www.collada.org/2005/11/COLLADASchema');
            rootNode.setAttribute('version', '1.4.1');

            asset = rootNode.appendChild(DOM.createElement('asset'));

            dateNode = asset.appendChild(DOM.createElement('created'));
            dateNode.appendChild(DOM.createTextNode(...
                datestr(now, 'yyyy-mm-ddTHH:MM:SSZ')));

            contributor = asset.appendChild(DOM.createElement('contributor'));
            authorNode = contributor.appendChild(...
                DOM.createElement('authoring_tool'));
            authorNode.appendChild(DOM.createTextNode('SBFSEMtools'));

            unitNode = asset.appendChild(DOM.createElement('unit'));
            unitNode.setAttribute('meter', '0.1');
            unitNode.setAttribute('name', 'meter');

            upAxis = asset.appendChild(DOM.createElement('up_axis'));
            upAxis.appendChild(DOM.createTextNode('Z_UP'));

            libScenes = rootNode.appendChild(DOM.createElement('library_visual_scenes'));
            visualScene = libScenes.appendChild(DOM.createElement('visual_scene'));
            visualScene.setAttribute('id', 'ID2');

            sceneNode = visualScene.appendChild(DOM.createElement('node'));
            sceneNode.setAttribute('name', 'SBFSEMtools');

            libNodes = rootNode.appendChild(DOM.createElement('library_nodes'));

            libGeometries = rootNode.appendChild(DOM.createElement('library_geometries'));

            % Add the faces and vertices of each patch in axis
            for i = 1:numel(graphNames)
                % Get the faces and vertices matching the current Tag
                FV = allFV(graphNames{i});
                % Reduce the number of faces
                if obj.reduceFac ~= 1
                    FV = reducepatch(FV, obj.reduceFac);
                end
                F = FV.faces;
                V = FV.vertices;
                fprintf('%s - %u faces and %u vertices\n',... 
                    graphNames{i}, numel(F), numel(V));

                % Add to the COLLADA document
                node = sceneNode.appendChild(DOM.createElement('node'));
                node.setAttribute('id', obj.getID('', 3, i));
                node.setAttribute('name', ['instance_', graphNames{i}]);

                matrix = node.appendChild(DOM.createElement('matrix'));
                matrix.appendChild(DOM.createTextNode(sprintf('%d ', eye(4))));

                instanceNode = node.appendChild(DOM.createElement('instance_node'));
                instanceNode.setAttribute('url', obj.getID('#', 4, i));

                node = libNodes.appendChild(DOM.createElement('node'));
                node.setAttribute('id',  obj.getID('', 4, i));
                node.setAttribute('name', graphNames{i});

                instanceGeometry = node.appendChild(...
                    DOM.createElement('instance_geometry'));
                instanceGeometry.setAttribute('url', obj.getID('#', 5, i));

                bindMaterial = instanceGeometry.appendChild(...
                    DOM.createElement('bind_material'));
                bindMaterial.appendChild(DOM.createElement('technique_common'));

                geometry = libGeometries.appendChild(DOM.createElement('geometry'));
                geometry.setAttribute('id', obj.getID('', 5, i));

                meshNode = geometry.appendChild(DOM.createElement('mesh'));
                source = meshNode.appendChild(DOM.createElement('source'));
                source.setAttribute('id', obj.getID('', 6, i));

                floatArray = source.appendChild(DOM.createElement('float_array'));
                floatArray.setAttribute('id', obj.getID('', 7, i));
                floatArray.setAttribute('count', num2str(numel(V)));
                floatArray.appendChild(DOM.createTextNode(sprintf('%g ', V')));

                techniqueCommon = source.appendChild(...
                    DOM.createElement('technique_common'));

                accessor = techniqueCommon.appendChild(DOM.createElement('accessor'));
                accessor.setAttribute('count', num2str(size(V, 1)));
                accessor.setAttribute('source', obj.getID('#', 7, i));
                accessor.setAttribute('stride', '3');

                for j = {'X', 'Y', 'Z'}
                    param = accessor.appendChild(DOM.createElement('param'));
                    param.setAttribute('name', j);
                    param.setAttribute('type', 'float');
                end

                vertices = meshNode.appendChild(DOM.createElement('vertices'));
                vertices.setAttribute('id', obj.getID('', 8, i));
                vertexInput = vertices.appendChild(DOM.createElement('input'));
                vertexInput.setAttribute('semantic', 'POSITION');
                vertexInput.setAttribute('source', obj.getID('#', 6, i));

                triangles = meshNode.appendChild(DOM.createElement('triangles'));
                triangles.setAttribute('count', num2str(size(F, 1)));
                triangleInput = triangles.appendChild(DOM.createElement('input'));
                triangleInput.setAttribute('offset', '0');
                triangleInput.setAttribute('semantic', 'VERTEX');
                triangleInput.setAttribute('source', obj.getID('#', 8, i));

                p = triangles.appendChild(DOM.createElement('p'));
                p.appendChild(DOM.createTextNode(sprintf('%d ', (F-1)')));
            end

            scene = rootNode.appendChild(DOM.createElement('scene'));
            instanceVisualScene = scene.appendChild(...
                DOM.createElement('instance_visual_scene'));
            instanceVisualScene.setAttribute('url', '#ID2');

            % Write file
            fid = fopen(obj.fName, 'w');
            fprintf(fid, '%s', xmlwrite(DOM));
            fclose(fid);
        end
    end
    
    methods (Static)
        function s = getID(p, n, i)
            % GETID  Generate some quick IDs
            s = sprintf('%sID%d', p, n+(i-1)*10);
        end
    end
end