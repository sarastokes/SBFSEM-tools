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
    %
    % Methods:
    %   obj.render('ax', axHandle, 'facecolor', 'b'); 
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
        r1411 = sbfsem.render.Cylinder(sbfsem.Neuron(1411, 'i'));
        r1441 = sbfsem.render.Cylinder(sbfsem.Neuron(1441, 'i'));
        % Render in a new figure
        r1411.render();
        % Add to existing figure
        r1441.render('ax', gca, 'facecolor', [0.8 0.5 0]);
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

    properties (Constant = true, Hidden = true)
        CIRCLEPTS = 10;         % Points for line3
        CYLINDERPTS = 20;       % Points per around RC
        BRIDGEPTS = 2;          % Points per 2 annotations for RC
    end
    
    methods
        function obj = Cylinder(neuron, varargin)
            assert(isa(neuron, 'sbfsem.Neuron'), 'Input a Neuron object');
            
            ip = inputParser();
            addParameter(ip, 'method', 1, @(x) ismember(x, [1 2]));
            addParameter(ip, 'reduceFac', 1);
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
                obj.FV = obj.createCurveMeshes();
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
            %   facecolor       Color for render faces
            %   useSegments     Render as a single patch
            %   reduce          Apply patch face reduction

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'faceColor', [0.5 0 0.8],...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'useSegments', false, @islogical);
            addParameter(ip, 'reduce', false, @islogical);
            parse(ip, varargin{:});
            
            if obj.reduceFac == 1
                doReduction = false;
            else
                doReduction = ip.Results.reduce;
                if doReduction
                    fprintf('Reduced patch to %u %%\n', 100*obj.reduceFac);
                end
            end
            
            faceColor = ip.Results.faceColor;
            
            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
                lightangle(45,30);
                lightangle(225,30);
            else
                ax = ip.Results.ax;
            end
            
            hold(ax, 'on');
            
            if ip.Results.useSegments
                for i = 1:numel(obj.FV)
                    p = patch(obj.FV{i},...
                        'FaceColor', faceColor,...
                        'EdgeColor', 'none',...
                        'Tag', sprintf('c%u', obj.ID),...
                        'Parent', ax);
                    if doReduction
                        reducepatch(p, obj.reduceFac);
                    end
                end
            else
                allFV = obj.condense();
                if obj.smoothIter ~= 0

                    allFV = obj.smooth(allFV, obj.smoothIter);
                end
                p = patch(allFV,...
                    'FaceColor', faceColor,...
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
            if nargin < 2
                fname = sprintf('c%u.dae', obj.ID);
            end
            
            filePath = uigetdir();
            
            disp('Condensing meshes');
            allFV = obj.condense();
            
            if obj.reduceFac ~= 1
                allFV = reducepatch(allFV, obj.reduceFac);
                fprintf('Reduced patch to %u%%\n', obj.reduceFac * 100);
            end
            
            fprintf('Saving as %s\n', [filePath filesep fname]);
            writeDAE([filePath, filesep, fname],...
                allFV.vertices, allFV.faces);
        end
        
        function FV = condense(obj)
            % CONDENSE  Single face/vertex struct
            %
            % See also: CONCATENATEMESHES
            FV = concatenateMeshes(vertcat(obj.FV{:}));
        end
    end
    
    methods (Access = private)
        function FV = createPolygonMeshes(obj) 
            % CREATEPOLYGONMESHES
            %
            % Creates a polygon mesh of each dendrite segment using two
            % algorithms for creating rotated cylinders. The algorithm used
            % is determined for each segment individually.
            
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
                    [x, y, z] = gencyl(locations{i}', radii{i});
                    [fv.faces, fv.vertices] = surf2patch(...
                        x, y, z, 'triangles');
                end
                FV = cat(1, FV, fv);
            end
        end

        function FV = createCurveMeshes(obj)
            locations = obj.subGraphs.XYZum;
            radii = obj.subGraphs.Rum;

            FV = {};

            for i = 1:height(obj.subGraphs)
                fv = curveToMesh2(locations{i}, radii{i});
                FV = cat(1, FV, fv);
            end
        end
    end
    
    methods (Access = private)       
        function [FV, gencylFlag] = Line3(obj, data, radius)
            x = data(:,1);
            y = data(:,2);
            z = data(:,3);
            N = obj.CIRCLEPTS;
            
            % Flags situations where fminsearch doesn't converge. These
            % segments will then be sent to alternative rendering method.
            gencylFlag = 0;
            options = optimset('Display', 'off');
            
            % Vertex points around each circle
            angles=0:(360/N):359.999;
            
            % Buffer distance between two line pieces.
            bufferDist = max(radius);
            
            D = sqrt((diff(x)).^2 + (diff(y)).^2 + (diff(z)).^2);
            
            if ((min(D)/2.2) < bufferDist)
                bufferDist = min(D)/2.2;
            end
            
            % Check if the plotted line is closed
            isClosed = isequal(data(1,:), data(end,:));
            if isClosed
                disp('Found a closed line');
            end
            
            % Calculate normal vectors on every line point (Nx3)
            normal = [diff(data); data(end,:) - data(end-1,:)];
            normal = normal ./ (sqrt(normal(:,1).^2 + normal(:,2).^2 ...
                + normal(:,3).^2) * ones(1,3));
            
            % Create a list to store vertex points
            FV.vertices = zeros(N * length(data), 3);
            
            % In plane rotation of 2d circle coordinates
            jm = 0;
            
            % Track the number of cylinder elements
            numCylinders = 0;
            
            % Calculate the 3D circle coordinates of the first circle/cylinder
            [a, b] = obj.getab(normal(1, :));
            circm = obj.normalCircle(angles, jm, a, b);
            
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
            circmo = obj.normalCircle([0 120 240], 0, a, b);
            
            % Loop through all line pieces.
            for i=1:length(data)-1
                % Create main cylinder between 2 line points. This consists
                % of two connected circles.
                iNormal=normal(i,:); iData=data(i,:);
                
                % Calculate the 3D circle coordinates
                [a, b] = obj.getab(iNormal);
                circm = obj.normalCircle(angles,jm,a,b);
                
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
                [a, b] = obj.getab(ijNormal);
                [jm, ~, exitFlag] = fminsearch(...
                    @(j) obj.minimizeRot([0 120 240], circmo, j, a, b), jm,...
                    options);
                if exitFlag == 0
                    gencylFlag = 1;
                end
                
                % Keep a 3 point circle for rotation alignment with the
                % next circle
                [a, b] = obj.getab(ijNormal);
                circmo = obj.normalCircle([0 120 240], jm, a, b);
                
                % Calculate the 3D circle coordinates
                circm = obj.normalCircle(angles, jm, a, b);
                
                % Translate the circle on it's position on the line
                circmp = circm*radius(i+1) + ones(N,1)*(ijData);
                
                numCylinders = numCylinders+1;
                FV.vertices(((numCylinders-1)*N+1):(numCylinders*N), :) =...
                    [circmp(:,1), circmp(:,2), circmp(:,3)];
                
                % Rotate circle coordinates in plane to align with the
                % previous circle by minimizing distance between the
                % coordinates of two circles with 3 coordinates.
                [a, b] = obj.getab(jNormal);                
                [jm, ~, exitFlag] = fminsearch(...
                    @(j) obj.minimizeRot([0, 120, 240], circmo, j, a, b), jm,...
                    options);
                if exitFlag == 0
                    gencylFlag = 0;
                end
                
                % Keep a 3 point circle for rotation alignment with the
                % next circle
                circmo = obj.normalCircle([0, 120, 240], jm, a, b);
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
            
            % Faces of one meshed line-part (cylinder)
            Fb=[[1:N, (1:N)+1];...
                [(1:N)+N, (1:N)];...
                [(1:N)+N+1, (1:N) + N + 1]]';
            Fb(N, 3) = 1 + N;
            Fb(N*2, 1) = 1;
            Fb(N*2, 3) = 1 + N;
            
            % Create TRI face list
            FV.faces = zeros(N*2*(numCylinders-1), 3);
            for i = 1:numCylinders-1
                FV.faces(((i-1)*N*2+1):((i)*N*2), 1:3) =...
                    (Fb + (i-1)*N);
            end
        end
        
        function [err,circm] = minimizeRot(obj, angles, circmo, angleoffset, a, b)
            % This function calculates a distance "error", between the same
            % coordinates in two circles on a line.
            [circm]=obj.normalCircle(angles,angleoffset,a,b);
            dist=(circm-circmo).^2;
            err=sum(dist(:));
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
        
        function [X, a, b] = normalCircle(angles, angleoffset, a, b)
            % This function rotates a 2D circle in 3D to be orthogonal with
            % a normal vector.
            
            % 2D circle coordinates.
            circ=[cosd(angles+angleoffset); sind(angles+angleoffset)]';
            
            X = [circ(:,1).*a(1) circ(:,1).*a(2) circ(:,1).*a(3)]+...
                [circ(:,2).*b(1) circ(:,2).*b(2) circ(:,2).*b(3)];
        end
        
        function [a, b] = getab(normal)
            % A normal vector only defines two rotations not the in plane
            % rotation. Thus a (random) v ector is needed which is not
            % orthogonal with the normal vector.
            randomv = [0.57745, 0.5774, 0.57735];

            % Calculate 2D to 3D transform parameters
            a = normal - randomv/(randomv*normal'); 
            
            a = a/sqrt(a*a');
            
            b = cross(normal, a); 
            b = b / sqrt(b * b');
        end
        
        function saveDAE(filename, FV)
            % WRITEDAE  Write a mesh to a Collada .dae scene file.

            F = FV.faces;
            V = FV.vertices;
            
            % Name scene as the filename without path or .dae
            sceneName = strsplit(filename, filesep);
            sceneName = sceneName{end};
            sceneName(end-3:end) = [];
            
            % COLLADA setup
            DOM = com.mathworks.xml.XMLUtils.createDocument('COLLADA');
            rootNode = DOM.getDocumentElement;
            
            rootNode.setAttribute(...
                'xmlns','http://www.collada.org/2005/11/COLLADASchema');
            rootNode.setAttribute('version', '1.4.1');

            assetNode = rootNode.appendChild(DOM.createElement('asset'));

            dateNode = AssetNode.appendChild(DOM.createElement('created'));
            dateNode.appendChild(DOM.createTextNode(...
                datestr(now, 'yyyy-mm-ddTHH:MM:SSZ')));
            authorNode = ContributorNode.appendChild(...
                DOM.createElement('authoring_tool'));
            authorNode.appendChild(DOM.createTextNode('SBFSEMtools'));

            unitNode = assetNode.appendChild(DOM.createElement('unit'));
            unitNode.setAttribute('meter', '1');
            unitNode.setAttribute('name', 'micrometer');

            upNode = assetNode.appendChild(DOM.createElement('up_axis'));
            upNode.appendChild(DOM.createTextNode('Z_UP'));
            
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