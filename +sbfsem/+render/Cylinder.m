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
    %   FV          Struct with faces, vertices of each segmetb
    %
    % Methods:
    %   obj.render('ax', axHandle, 'facecolor', 'b'); 
    %   FV = condense(obj);
    %   fh = plot(obj); 
    %   obj.dae();
    %
    %   See also: DENDRITESEGMENTATION, GENCYL
    %
    %   History:
    %       11Dec2017 - SSP 
    %       21Dec2017 - SSP - cleaned up, dae export, improved lighting
    
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
    
    properties (SetAccess = private)
        ID
        subGraphs
        G
        FV
    end
    
    properties (Transient = true, Hidden = true)
        neuron
    end
    
    properties (Constant = true, Hidden = true)
        CIRCLEPTS = 12;
        CYLINDERPTS = 20;
        BRIDGEPTS = 2;
    end
    
    methods
        function obj = Cylinder(neuron)
            assert(isa(neuron, 'sbfsem.Neuron'), 'Input a Neuron object');
            
            obj.ID = neuron.ID;
            obj.neuron = neuron;
            obj.G = graph(neuron);
            
            [~, obj.subGraphs] = dendriteSegmentation(neuron);
            obj.FV = obj.createPolygonMeshes();
        end
        
        function fh = plot(obj)
            fh = sbfsem.ui.FigureView(1);
            plot(obj.G, 'Layout', 'force', 'Parent', fh.ax);
            axis tight;
            axis off;
        end
        
        function render(obj, varargin)
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'faceColor', [0.5 0 0.8],...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'useSegments', false, @islogical);
            addParameter(ip, 'reduce', 0, @(x)...
                validateattributes(x, {'numeric'}, {'<=', 1, '>=',0}));
            parse(ip, varargin{:});
            
            faceColor = ip.Results.faceColor;
            
            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
            else
                ax = ip.Results.ax;
            end
            
            hold(ax, 'on');
            
            for i = 1:numel(obj.FV)
                patch(obj.FV{i},...
                    'FaceColor', faceColor,...
                    'EdgeColor', 'none',...
                    'Tag', sprintf('c%u', obj.ID),...
                    'Parent', ax);
            end

            axis(ax, 'equal');
            axis(ax, 'tight');
            lightangle(45,30);
            lightangle(225,30);
            lighting phong;
        end
        
        function dae(obj, fname)
            if nargin < 2
                fname = sprintf('c%u.dae', obj.ID);
            end
            
            filePath = uigetdir();
            
            disp('Condensing meshes');
            FV = obj.condense();
            
            fprintf('Saving as %s\n', [filePath filesep fname]);
            obj.writeDAE([filePath, filesep, fname],...
                FV.vertices, FV.faces);
        end
        
        function FV = condense(obj)
            % CONDENSE  Wrapper for geom3d concatenateMeshes See also:
            % CONCATENATEMESHES
            FV = concatenateMeshes(vertcat(obj.FV{:}));
        end
    end
    
    methods (Access = private)
        function FV = createPolygonMeshes(obj) 
            if isempty(obj.subGraphs)
                obj.subGraphs = dendriteSegmentation(obj.neuron);
            end
            
            % Pull data from table
            locations = obj.subGraphs.XYZum;
            radii = obj.subGraphs.Rum;
            
            FV = {};
            
            for i = 1:height(obj.subGraphs)
                if size(obj.subGraphs.XYZum{i}, 1) > 2
                    [fv, gencylFlag] = obj.Line3(locations{i}, radii{i});
                    fv = obj.smooth(fv);
                    if gencylFlag
                        fv = [];
                        [x, y, z] = gencyl(locations{i}', radii{i});
                        [fv.faces, fv.vertices] = surf2patch(...
                            x, y, z, 'triangles');
                    end                   
                else
                    % Use GENCYL for small sections
                    [x, y, z] = gencyl(locations{i}', radii{i});
                    [fv.faces, fv.vertices] = surf2patch(...
                        x, y, z, 'triangles');
                end
                FV = cat(1, FV, fv);
            end
        end
    end
    
    methods (Access = private)
        function [X, Y, Z, A] = rotatedCylinder(obj, locations, radii)
            % ROTATEDCYLINDER  Generates series of rotated cylinders See
            % also: gencyl
            
            N = numel(radii);
            
            D = diff(locations , 1 , 2 );
            L = sqrt(sum(D.^2));
            
            % Interpolate radius
            if obj.BRIDGEPTS > 2
                radii = interp1( 1:N , radii ,...
                    linspace(1,N, obj.BRIDGEPTS*(N-1) - (N-2) ) , 'spline' );
            end
            
            % Axis and angle of rotation for each cylinder
            Qvec = cross( [0;0;1]*ones(1,N-1) , D );
            A = acos(dot([0;0;1]*ones(1,N-1), D)./L);
            
            % Init
            endPt = 0;
            endRadius = 1;
            X = zeros((N-1) * obj.BRIDGEPTS, obj.CYLINDERPTS+1);
            Y = zeros((N-1) * obj.BRIDGEPTS, obj.CYLINDERPTS+1);
            Z = zeros((N-1) * obj.BRIDGEPTS, obj.CYLINDERPTS+1);
            
            for i = 1:(N-1)
                % Start and end indices
                startPt = endPt + 1;
                endPt = i*obj.BRIDGEPTS;
                
                % Radius points
                startRadius = endRadius;
                endRadius = startRadius + (obj.BRIDGEPTS-1);
                
                % Create matlab cylinder
                [tx, ty, tz] = cylinder(radii(startRadius:endRadius), obj.CYLINDERPTS);
                
                % Get the quaternion rotation matrix
                Q = obj.qrotation(Qvec(:,i), A(i));
                
                % Rotate and scale cylinder
                ty = ty(:)'; tx = tx(:)'; tz = tz(:)';
                C = bsxfun(@plus, Q * vertcat(tx, ty, L(i)*tz),...
                    locations(:,1));
                
                X(startPt:endPt,:) = reshape(C(1,:)', obj.BRIDGEPTS, obj.CYLINDERPTS+1);
                Y(startPt:endPt,:) = reshape(C(2,:)', obj.BRIDGEPTS, obj.CYLINDERPTS+1);
                Z(startPt:endPt,:) = reshape(C(3,:)', obj.BRIDGEPTS, obj.CYLINDERPTS+1);
            end
        end
        
        function [FV, gencylFlag] = Line3(obj, data, radius)
            x = data(:,1);
            y = data(:,2);
            z = data(:,3);
            N = obj.CIRCLEPTS;
            
            % Flags situations where fminsearch doesn't converge. These
            % segments will then be sent to alternative rendering method.
            gencylFlag = 0;
            
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
            
            % Number of triangelized cylinder elements added to plot the 3D
            % line
            numCylinders = 0;
            
            % Calculate the 3D circle coordinates of the first circle/cylinder
            [a, b] = obj.getab(normal(1, :));
            circm = obj.normalCircle(angles, jm, a, b);
            
            % If not a closed line, add a half sphere made by 5 cylinders
            % add the line start.
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
                % Create main cylinder between 2 line points This consists
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
                ijData = 0.5858*jData...
                    + 0.4142*(0.5*((jData + bufferDist*jNormal)...
                    + (jData - bufferDist*iNormal)));
                
                % Rotate circle coordinates in plane to align with the
                % previous circle by minimizing distance between the
                % coordinates of two circles with 3 coordinates.
                [a, b] = obj.getab(ijNormal);
                [jm, ~, exitFlag] = fminsearch(...
                    @(j) obj.minimizeRot([0 120 240], circmo, j, a, b), jm);
                if exitFlag == -1
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
                    @(j) obj.minimizeRot([0, 120, 240], circmo, j, a, b), jm);
                if exitFlag == -1
                    gencylFlag = 0;
                end
                
                % Keep a 3 point circle for rotation alignment with the
                % next circle
                circmo = obj.normalCircle([0, 120, 240], jm, a, b);
            end
            
            % If not a closed line, add a half sphere made by 5 cylinders
            % add the line end. Otherwise add the starting circle to the
            % line end.
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
        
        function [err,circm]=minimizeRot(obj, angles, circmo, angleoffset, a, b)
            % This function calculates a distance "error", between the same
            % coordinates in two circles on a line.
            [circm]=obj.normalCircle(angles,angleoffset,a,b);
            dist=(circm-circmo).^2;
            err=sum(dist(:));
        end
    end
    
    methods (Static)
        function q = qrotation(vec, ang)
            %ROTATION  Quaternion rotation matrix
            cphi = cos(ang/2);
            sphi = sin(ang/2);
            
            vec = vec/norm(vec);
            vec = vec(:)';
            vals = num2cell([cphi vec*sphi]);
            [a, b, c, d] = vals{:};
            
            q = [ 1 - 2*c^2 - 2*d^2 , 2*b*c - 2*d*a     , 2*b*d + 2*c*a ; ...
                2*b*c + 2*d*a     , 1 - 2*b^2 - 2*d^2 , 2*c*d - 2*b*a ; ...
                2*b*d - 2*c*a     , 2*c*d + 2*b*a     , 1 - 2*c^2 - 2*b^2 ];
        end
        
        function FV = smooth(FV)
            % SMOOTH  Structure input/output for geom3d smoothMesh See
            % also: SMOOTHMESH
            [FV.vertices, FV.faces] = smoothMesh(FV.vertices, FV.faces);
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
        
        function writeDAE(filename,varargin)
            % WRITEDAE  Write a mesh to a Collada .dae scene file.
            
            function s = id(p,n,i)
                s = sprintf('%sID%d',p,n+(i-1)/2*10);
            end
            
            docNode = com.mathworks.xml.XMLUtils.createDocument('COLLADA');
            docRootNode = docNode.getDocumentElement;
            docRootNode.setAttribute(...
                'xmlns','http://www.collada.org/2005/11/COLLADASchema');
            docRootNode.setAttribute('version','1.4.1');
            asset = docNode.createElement('asset');
            unit = docNode.createElement('unit');
            unit.setAttribute('meter','0.0254000');
            unit.setAttribute('name','inch');
            asset.appendChild(unit);
            up_axis = docNode.createElement('up_axis');
            up_axis.appendChild(...
                docNode.createTextNode('Y_UP'));
            asset.appendChild(up_axis);
            docRootNode.appendChild(asset);
            
            visual_scenes = docNode.createElement('library_visual_scenes');
            visual_scene = docNode.createElement('visual_scene');
            visual_scene.setAttribute('id','ID2');
            sketchup = docNode.createElement('node');
            sketchup.setAttribute('name','SketchUp');
            
            library_nodes = docNode.createElement('library_nodes');
            
            library_geometries = docNode.createElement('library_geometries');
            
            for i = 1:2:numel(varargin)
                V = varargin{i};
                F = varargin{i+1};
                
                node = docNode.createElement('node');
                node.setAttribute('id',id('',3,i));
                node.setAttribute('name',sprintf('instance_%d',i-1));
                
                matrix = docNode.createElement('matrix');
                matrix.appendChild(docNode.createTextNode(sprintf('%d ',eye(4))));
                node.appendChild(matrix);
                instance_node = docNode.createElement('instance_node');
                instance_node.setAttribute('url',id('#',4,i));
                node.appendChild(instance_node);
                sketchup.appendChild(node);
                
                node = docNode.createElement('node');
                node.setAttribute('id',id('',4,i));
                node.setAttribute('name',sprintf('skp%d',i-1));
                instance_geometry = docNode.createElement('instance_geometry');
                instance_geometry.setAttribute('url',id('#',5,i));
                bind_material = docNode.createElement('bind_material');
                bind_material.appendChild(docNode.createElement('technique_common'));
                instance_geometry.appendChild(bind_material);
                node.appendChild(instance_geometry);
                library_nodes.appendChild(node);
                
                geometry = docNode.createElement('geometry');
                geometry.setAttribute('id',id('',5,i));
                mesh = docNode.createElement('mesh');
                source = docNode.createElement('source');
                source.setAttribute('id',id('',6,i));
                float_array = docNode.createElement('float_array');
                float_array.setAttribute('id',id('',7,i));
                float_array.setAttribute('count',num2str(numel(V)));
                float_array.appendChild(...
                    docNode.createTextNode(sprintf('%g ',V')));
                source.appendChild(float_array);
                technique_common = docNode.createElement('technique_common');
                accessor = docNode.createElement('accessor');
                accessor.setAttribute('count',num2str(size(V,1)));
                accessor.setAttribute('source',id('#',7,i));
                accessor.setAttribute('stride','3');
                for name = {'X','Y','Z'}
                    param = docNode.createElement('param');
                    param.setAttribute('name',name);
                    param.setAttribute('type','float');
                    accessor.appendChild(param);
                end
                technique_common.appendChild(accessor);
                source.appendChild(technique_common);
                mesh.appendChild(source);
                vertices = docNode.createElement('vertices');
                vertices.setAttribute('id',id('',8,i));
                input = docNode.createElement('input');
                input.setAttribute('semantic','POSITION');
                input.setAttribute('source',id('#',6,i));
                vertices.appendChild(input);
                mesh.appendChild(vertices);
                triangles = docNode.createElement('triangles');
                triangles.setAttribute('count',num2str(size(F,1)));
                input = docNode.createElement('input');
                input.setAttribute('offset','0');
                input.setAttribute('semantic','VERTEX');
                input.setAttribute('source',id('#',8,i));
                triangles.appendChild(input);
                p = docNode.createElement('p');
                p.appendChild(...
                    docNode.createTextNode(sprintf('%d ',(F-1)')));
                triangles.appendChild(p);
                mesh.appendChild(triangles);
                geometry.appendChild(mesh);
                library_geometries.appendChild(geometry);
            end
            
            visual_scene.appendChild(sketchup);
            visual_scenes.appendChild(visual_scene);
            docRootNode.appendChild(visual_scenes);
            docRootNode.appendChild(library_nodes);
            
            docRootNode.appendChild(library_geometries);
            
            scene = docNode.createElement('scene');
            instance_visual_scene = docNode.createElement('instance_visual_scene');
            instance_visual_scene.setAttribute('url','#ID2');
            scene.appendChild(instance_visual_scene);
            docRootNode.appendChild(scene);
            
            f = fopen(filename,'w');
            fprintf(f,'%s',xmlwrite(docNode));
            fclose(f);
        end
    end
end