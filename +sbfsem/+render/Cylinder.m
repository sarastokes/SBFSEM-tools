classdef Cylinder < handle
    % CYLINDER
    %
    % Inputs:
    %   neuron      Neuron object
    %
    % Properties:
    %   ID          Neuron ID number 
    %   subGraphs   Graph segments 
    %   G           Graph
    %   FV          Struct with faces, vertices of each segment
    %   reduceFac   Percent of faces to retain in DAE (1 = 100%)
    %   method      Try alternative algorithm 2 (default = 1)
    % Dependent properties:
    %   allFV       Single condensed FV structure
    %
    %
    % Methods:
    %   obj.render('ax', axHandle, 'FaceColor', 'b'); 
    %   FV = condense(obj);
    %   fh = plot(obj); 
    %   obj.dae();
    %
    %   See also: DENDRITESEGMENTATION, GENCYL, PLOT3T
    %
    %   History:
    %       11Dec2017 - SSP 
    %       21Dec2017 - SSP - cleaned up, dae export, improved lighting
    %
    % Examples:
    %{
        % Import the neurons
        c1411 = Neuron(1411, 'i');
        c1441 = Neuron(1441, 'i');
        % Build the 3D models
        c1411.build();
        c1441.build();
        % Render in a new figure
        r1411.render();
        % Add to existing figure
        r1441.render('ax', gca, 'FaceColor', [0.8 0.5 0]);
        % Export both to COLLADA .dae files
        dae(r1411); dae(r1441);
    %}
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
        subGraphs
        G
        FV
        
        reduceFac = 1;
        smoothIter = 1;
    end
    
    properties (GetAccess = public, Dependent = true, Hidden = true)
        allFV
    end

    properties (Constant = true, Hidden = true)
        CIRCLEPTS = 10;         % Points for line3
        CYLINDERPTS = 20;       % Points per around RC
        BRIDGEPTS = 2;          % Points per 2 annotations for RC
        CURVEPTS = 16;          % Points for curveToMesh2
    end
    
    methods
        function obj = Cylinder(neuron, varargin)
            assert(isa(neuron, 'NeuronAPI'), 'Input a Neuron object');
            
            ip = inputParser();
            addParameter(ip, 'method', 1, @(x) ismember(x, [1 2]));
            addParameter(ip, 'reduceFac', 1);
            addParameter(ip, 'curvePts', obj.CURVEPTS, @isnumeric);
            addParameter(ip, 'smoothIter', 1);
            parse(ip, varargin{:});

            obj.ID = neuron.ID;
            obj.G = graph(neuron);
            
            obj.setReduction(ip.Results.reduceFac);
            obj.setSmoothIter(ip.Results.smoothIter);
            
            % Divide neuron into degree<3 segments
            [~, obj.subGraphs] = dendriteSegmentation(neuron);

            % Create the meshes
            if ip.Results.method == 1
                obj.FV = obj.createPolygonMeshes();
            else
                % Smoothing is v detrimental to the curve meshes
                obj.setSmoothIter(0);
                obj.FV = obj.createCurveMeshes(ip.Results.curvePts);
            end
        end
        
        function allFV = get.allFV(obj)
            % Dependent get method for single FV struct
            if ~isempty(obj.FV)
                allFV = obj.condense();
            else
                warning('CYLINDER: FV is empty');
                allFV = [];
            end
        end

        function setReduction(obj, x)
            % SETREDUCTION
            %
            % Input:
            %   x           Reduction factor between 0-1
            %               where 1 keeps all faces, 0.5 keeps 50%
            % -------------------------------------------------------------
            assert(x >= 0 & x <= 1, 'Reduction factor must be between 0-1');
            obj.reduceFac = x;
        end
        
        function setSmoothIter(obj, numIter)
            % SETSMOOTHING
            obj.smoothIter = numIter;
        end
        
        function fh = plot(obj)
            % PLOT  Show the graph used for dendrite segmentation
            
            fh = sbfsem.ui.FigureView(1);
            plot(obj.G, 'Layout', 'force', 'Parent', fh.ax);
            axis tight;
            axis off;
        end
        
        function render(obj, varargin)
            % RENDER
            %
            % Optional key/value inputs:
            %   ax              Existing axis handle (default = new figure)
            %   FaceColor       Color for render faces
            %   useSegments     Render as a single patch
            %   reduce          Apply patch face reduction

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'FaceColor', [0.5 0 0.8],...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'FaceAlpha', 1, @isnumeric);
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'useSegments', false, @islogical);
            addParameter(ip, 'reduce', false, @islogical);
            parse(ip, varargin{:});
            FaceColor = ip.Results.FaceColor;
            FaceAlpha = ip.Results.FaceAlpha;
            
            if obj.reduceFac == 1
                doReduction = false;
            else
                doReduction = ip.Results.reduce;
                if doReduction
                    fprintf('Reduced patch to %u %%\n', 100*obj.reduceFac);
                end
            end

            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
                lightangle(45,30);
                lightangle(225,30);
                hold(ax, 'on');
            else
                ax = ip.Results.ax;
            end

            if ip.Results.useSegments
                for i = 1:numel(obj.FV)
                    p = patch(obj.FV{i},...
                        'FaceColor', FaceColor,...
                        'FaceAlpha', FaceAlpha,...
                        'EdgeColor', 'none',...
                        'Tag', sprintf('c%u', obj.ID),...
                        'Parent', ax);
                    if doReduction
                        reducepatch(p, obj.reduceFac);
                    end
                end
            else % Condense into a single mesh
                meshFV = obj.allFV;
                if obj.smoothIter ~= 0
                    meshFV = obj.smooth(meshFV, obj.smoothIter);
                end
                p = patch(meshFV,...
                    'FaceColor', FaceColor,...
                    'FaceAlpha', FaceAlpha,...
                    'EdgeColor', 'none',...
                    'Tag', sprintf('c%u', obj.ID),...
                    'Parent', ax);
                if doReduction
                    reducepatch(p, obj.reduceFac);
                end
            end
            
            axis(ax, 'equal');
            axis(ax, 'tight');
            lighting phong;
        end
        
        function dae(obj, fname)
            % DAE
            
            if nargin < 2
                fname = sprintf('c%u.dae', obj.ID);
            end
            
            filePath = uigetdir();
            
            meshFV = obj.allFV;
            
            if obj.reduceFac ~= 1
                meshFV = reducepatch(meshFV, obj.reduceFac);
                fprintf('Reduced patch to %u%%\n', obj.reduceFac * 100);
            end
            
            fprintf('Saving as %s\n', [filePath filesep fname]);
            obj.saveDAE([filePath, filesep, fname], meshFV);
        end
        
        function FV = condense(obj)
            % CONDENSE  Single face/vertex struct
            %
            % See also: CONCATENATEMESHES
            if numel(obj.FV) == 1
                FV = obj.FV{1};
            else
                validFV = cell(0,0);
                for i = 1:numel(obj.FV)
                    if nnz(isnan(obj.FV{i}.vertices))
                        fprintf('Not including segment %u\n', i)
                    else
                        validFV = cat(1, validFV, obj.FV{i});
                    end
                end
                FV = concatenateMeshes(vertcat(validFV{:}));
            end
        end
    end
    
    methods (Access = private)
        function FV = createPolygonMeshes(obj) 
            % CREATEPOLYGONMESHES
            %
            % Creates a polygon mesh of each dendrite segment using two
            % algorithms for creating rotated cylinders. The algorithm used
            % is determined for each segment individually. The two
            % algorithms are modified versions of gencyl and plot3t.
            % -------------------------------------------------------------
            
            % Pull data from table
            locations = obj.subGraphs.XYZum;
            radii = obj.subGraphs.Rum;
            
            FV = {};
            
            for i = 1:height(obj.subGraphs)
                if size(obj.subGraphs.XYZum{i}, 1) > 2
                    [fv, gencylFlag] = obj.Line3(locations{i}, radii{i});                    
                    if gencylFlag
                        fprintf('Segment %u - switched algorithms\n', i);
                        [x, y, z] = gencyl(locations{i}', radii{i});
                        if nnz(isnan(x)) > 0
                            % Very rarely, gencyl produces a few NaNs
                            % If this becomes more frequent I'll fix it
                            fprintf('Found %u NaNs\n', nnz(isnan(x)));     
                        else                                  
                            fv = [];
                            [fv.faces, fv.vertices] = surf2patch(...
                                x, y, z, 'triangles');
                        end
                    end
                else % Gencyl for smaller sections
                    try
                        [x, y, z] = gencyl(locations{i}', radii{i});
                        [fv.faces, fv.vertices] = surf2patch(...
                            x, y, z, 'triangles');
                    catch
                        fprintf('Small segments gencyl failed at %u\n', i);
                        fv = [];
                    end
                end
                if ~isempty(fv)
                    FV = cat(1, FV, fv);
                end
            end
        end

        function FV = createCurveMeshes(obj, curvePts)
            % CREATECURVEMESHES  A work in progress method
            locations = obj.subGraphs.XYZum;
            radii = obj.subGraphs.Rum;

            FV = {};

            for i = 1:height(obj.subGraphs)
                fv = curveToMesh2(locations{i}, radii{i}, curvePts);
                FV = cat(1, FV, fv);
            end
        end
    end
    
    methods (Access = private)       
        function [FV, gencylFlag] = Line3(obj, data, radius)
            
            % Flags situations where fminsearch doesn't converge. These
            % segments will then be sent to alternative rendering method.
            gencylFlag = 0;
            options = optimset('Display', 'off');
            
            x = data(:,1);
            y = data(:,2);
            z = data(:,3);
            
            % Each annotation is rendered as a circle of N points/vertices
            N = obj.CIRCLEPTS;            
            % Location of the points, in degrees
            angles=0:(360/N):359.999;            
            
            % Magnitude of the vector between the points
            mag = sqrt((diff(x)).^2 + (diff(y)).^2 + (diff(z)).^2);
            
            % Buffer distance between two line pieces.
            bufferDist = max(radius);
            if (min(mag)/2.2) < bufferDist
                bufferDist = min(mag)/2.2;
            end            
            
            % Calculate the normal by dividing the magnitude out of the
            % distance. This leaves a unit vector for the direction
            normal = diff(data) ./ (mag * ones(1,3));
            
            % Duplicate the last normal to keep the number of points
            % consistent throughout the code
            normal = [normal; normal(end,:)];
                        
            % Create a list to store vertex points
            FV.vertices = zeros(N * length(data), 3);
            
            % In plane rotation of 2d circle coordinates. The vertices
            % on two circles are connected to create faces. This rotates
            % the vertices on a circle so they align better with the points
            % on a neighboring circle.
            angleOffset = 0;
            
            % Track the number of cylinder elements
            numCylinders = 0;
            
            % Calculate the 3D circle coordinates of the first circle/cylinder
            [a, b] = getAB(normal(1, :));
            circm = normalCircle(angles, angleOffset, a, b);
            
            % Add a half sphere at line start
            for j=5:-0.5:1
                % Translate the circle on it's position on the line
                r = sqrt(1-(j/5)^2);
                circmp = r*radius(1)*circm + ones(N,1) * (data(1,:)...
                    - (j/5) * bufferDist * normal(1,:));
                % Create vertex list
                numCylinders = numCylinders + 1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N),:) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
            end
            
            % Make a 3 point circle for rotation alignment with the next
            % circle
            circmo = normalCircle([0 120 240], 0, a, b);
            
            % Loop through all line pieces.
            for i=1:length(data)-1
                % Create main cylinder between 2 line points. This consists
                % of two connected circles.
                iNormal=normal(i,:); iData=data(i,:);
                
                % Calculate the 3D circle coordinates
                [a, b] = getAB(iNormal);
                circm = normalCircle(angles, angleOffset, a, b);
                
                % Translate the circle on it's position on the line
                circmp = circm*radius(i)...
                    + ones(N,1)*(iData+bufferDist*iNormal);
                
                numCylinders = numCylinders + 1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N),:) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
                
                jNormal = normal(i+1,:);
                jData = data(i+1,:);
                
                % Translate the circle on it's position on the line
                circmp = circm*radius(i+1)...
                    + ones(N,1) * (jData - bufferDist*iNormal);
                
                numCylinders = numCylinders+1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N),:) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
                
                % Create in between circle to smoothly connect line pieces.
                ijNormal = iNormal + jNormal;
                ijNormal = ijNormal ./ sqrt(sum(ijNormal.^2));
                ijData = 0.5858* jData...
                    + 0.4142*(0.5*((jData + bufferDist*jNormal)...
                    + (jData - bufferDist*iNormal)));
                
                % Rotate circle coordinates in plane to align with the
                % previous circle by minimizing distance between the
                % coordinates of two circles with 3 coordinates.
                [a, b] = getAB(ijNormal);
                [angleOffset, ~, exitFlag] = fminsearch(...
                    @(j) minimizeRot([0 120 240], circmo, j, a, b),...
                    angleOffset, options);
                if exitFlag == 0
                    gencylFlag = 1;
                end
                
                % Keep a 3 point circle for rotation alignment with the
                % next circle
                [a, b] = getAB(ijNormal);
                circmo = normalCircle([0 120 240], angleOffset, a, b);
                
                % Calculate the 3D circle coordinates
                circm = normalCircle(angles, angleOffset, a, b);
                
                % Translate the circle on it's position on the line
                circmp = circm*radius(i+1) + ones(N,1)*(ijData);
                
                numCylinders = numCylinders+1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N), :) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
                
                % Rotate circle coordinates in plane to align with the
                % previous circle by minimizing distance between the
                % coordinates of two circles with 3 coordinates.
                [a, b] = getAB(jNormal);                
                [angleOffset, ~, exitFlag] = fminsearch(...
                    @(j) minimizeRot([0, 120, 240], circmo, j, a, b),...
                    angleOffset, options);
                if exitFlag == 0
                    gencylFlag = 0;
                end
                
                % Keep a 3 point circle for rotation alignment with the
                % next circle
                circmo = normalCircle([0, 120, 240], angleOffset, a, b);
            end
            
            % Add a half sphere made by 5 cylinders
            for j=1:0.5:5
                % Translate the circle on it's position on the line
                r = sqrt(1-(j/5)^2);
                circmp = r*radius(i+1)*circm + ones(N,1)*(data(i+1,:)...
                    + (j/5)*bufferDist*normal(i+1,:));
                % Create vertex list
                numCylinders = numCylinders+1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N),:) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
            end
            
            % Faces are defined by the connections between 3 vertices
            % Calculate for 1 segment (2 connected circles) then generalize
            % to the rest.
            Fb=[[1:N, (1:N)+1];...
                [(1:N)+N, (1:N)];...
                [(1:N)+N+1, (1:N) + N + 1]]';
            % Roll back the points at N*2+1 to N+1
            Fb(N, 3) = 1 + N;
            Fb(N*2, 3) = 1 + N;
            % Roll back the last row's X point from N+1 to 1
            Fb(N*2, 1) = 1;
            
            % Fill out the faces matrix
            FV.faces = zeros(N*2*(numCylinders-1), 3);
            for i = 1:numCylinders-1
                FV.faces(((i-1)*N*2+1):((i)*N*2), 1:3) =...
                    (Fb + (i-1)*N);
            end
        end
    end
    
    methods (Static)
        function FV = smooth(FV, numIter)
            % SMOOTH  Structure input/output for geom3d smoothMesh 
            % 
            % Inputs:
            %   numIter     Number of smooth iterations (default = 1)
            %
            % See also: SMOOTHMESH
            if nargin < 2
                numIter = 1;
            end
            [FV.vertices, FV.faces] = smoothMesh(FV.vertices, FV.faces, numIter);
        end
        
        function saveDAE(filename, FV)
            % WRITEDAE  Write a mesh to a Collada .dae scene file.

            F = FV.faces;
            V = FV.vertices;
            
            % Name scene as the filename without path or .dae
            sceneName = strsplit(filename, filesep);
            sceneName = sceneName{end};
            sceneName(end-3:end) = [];

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
            
            visualSceneLibrary = rootNode.appendChild(...
                DOM.createElement('library_visual_scenes'));
            visualScene = visualSceneLibrary.appendChild(...
                DOM.createElement('visual_scene'));
            visualScene.setAttribute('id', 'ID2');

            sceneNode = visualScene.appendChild(...
                DOM.createElement('node'));
            sceneNode.setAttribute('name', sceneName);
            
            library_nodes = rootNode.appendChild(...
                DOM.createElement('library_nodes'));            
            library_geometries = rootNode.appendChild(...
                DOM.createElement('library_geometries'));

            % write faces and vertices
            
            node = sceneNode.appendChild(...
                DOM.createElement('node'));
            node.setAttribute('id', 'ID3');
            node.setAttribute('name', 'instance0');
                
            matrix = node.appendChild(...
                DOM.createElement('matrix'));
            matrix.appendChild(...
                DOM.createTextNode(sprintf('%d ',eye(4))));

            instance_node = node.appendChild(...
                DOM.createElement('instance_node'));
            instance_node.setAttribute('url', '#ID4');
            
            node = library_nodes.appendChild(...
                DOM.createElement('node'));
            node.setAttribute('id', 'ID4');
            node.setAttribute('name','skp0');

            instance_geometry = node.appendChild(...
                DOM.createElement('instance_geometry'));
            instance_geometry.setAttribute('url', '#ID5');

            bind_material = instance_geometry.appendChild(...
                DOM.createElement('bind_material'));
            bind_material.appendChild(...
                DOM.createElement('technique_common'));
            
            geometry = library_geometries.appendChild(...
                DOM.createElement('geometry'));
            geometry.setAttribute('id', 'ID5');

            meshNode = geometry.appendChild(...
                DOM.createElement('mesh'));
            
            source = meshNode.appendChild(...
                DOM.createElement('source'));
            source.setAttribute('id', 'ID6');

            float_array = source.appendChild(...
                DOM.createElement('float_array'));
            float_array.setAttribute('id', 'ID7');
            float_array.setAttribute('count', num2str(numel(V)));
            float_array.appendChild(...
                DOM.createTextNode(sprintf('%g ',V')));

            technique_common = source.appendChild(...
                DOM.createElement('technique_common'));
            accessor = technique_common.appendChild(...
                DOM.createElement('accessor'));
            accessor.setAttribute('count', num2str(size(V,1)));
            accessor.setAttribute('source', '#ID7');
            accessor.setAttribute('stride','3');

            for name = {'X','Y','Z'}
                param = accessor.appendChild(...
                    DOM.createElement('param'));
                param.setAttribute('name', name);
                param.setAttribute('type', 'float');
            end
            
            vertices = meshNode.appendChild(...
                DOM.createElement('vertices'));
            vertices.setAttribute('id', 'ID8');
            inputNode = vertices.appendChild(...
                DOM.createElement('input'));
            inputNode.setAttribute('semantic', 'POSITION');
            inputNode.setAttribute('source', '#ID6');

            triangleNode = meshNode.appendChild(...
                DOM.createElement('triangles'));
            triangleNode.setAttribute('count', num2str(size(F,1)));
            inputNode = triangleNode.appendChild(...
                DOM.createElement('input'));
            inputNode.setAttribute('offset', '0');
            inputNode.setAttribute('semantic', 'VERTEX');
            inputNode.setAttribute('source', '#ID8');

            pNode = triangleNode.appendChild(...
                DOM.createElement('p'));
            pNode.appendChild(...
                DOM.createTextNode(sprintf('%d ',(F-1)')));
            
            scene = rootNode.appendChild(...
                DOM.createElement('scene'));
            instance_visual_scene = scene.appendChild(...
                DOM.createElement('instance_visual_scene'));
            instance_visual_scene.setAttribute('url', '#ID2');
            
            f = fopen(filename, 'w');
            fprintf(f,'%s', xmlwrite(DOM));
            fclose(f);
        end
    end
end