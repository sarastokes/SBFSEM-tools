classdef Cylinder < handle
    % CYLINDER
    
    properties (SetAccess = private)
        ID
        subGraphs
        nodeIDs
        G
    end
    
    properties (Transient = true)
        neuron
    end
    
    properties (Constant = true, Hidden = true)
        CIRCLEPTS = 20;
        BRIDGEPTS = 2;
    end
    
    methods
        function obj = Cylinder(neuron, useRC)
            assert(isa(neuron, 'sbfsem.Neuron'), 'Input a Neuron object');
            if nargin < 2
                useRC = false;
            else
                assert(islogical(useRC), 'useRC is t/f');
            end
            obj.ID = neuron.ID;
            obj.neuron = neuron;
            obj.G = graph(neuron);
            obj.nodeIDs = str2double(obj.G.Nodes{:,:});
            
            obj.subGraphs = obj.getSegments(useRC);
        end
        
        function fh = plot(obj)
            fh = sbfsem.ui.FigureView(1);
            plot(obj.G, 'Layout', 'force', 'Parent', fh.ax);
            axis tight;
            axis off;
        end
        
        function recalculate(obj, bridgePts)
            if nargin < 2
                bridgePts = 2;
            end
            obj.subGraphs = obj.getSegments(bridgePts);
        end
        
        function render(obj, varargin)            
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'faceColor', [0.5 0 0.8],...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'ax', [], @ishandle);
            parse(ip, varargin{:});
            
            faceColor = ip.Results.faceColor;
            
            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
            else
                ax = ip.Results.ax;
            end
            hold on;
            for i = 1:height(obj.subGraphs)
                surf(cell2mat(obj.subGraphs{i,'X'}),...
                    cell2mat(obj.subGraphs{i, 'Y'}),...
                    cell2mat(obj.subGraphs{i,'Z'}),...
                    'FaceColor', faceColor,... 
                    'EdgeColor', 'none',...
                    'Tag', sprintf('c%u', obj.ID),...
                    'Parent', ax);
            end
            axis(ax, 'equal');
        end        
    end
    
    methods (Access = private)
        function segmentTable = getSegments(obj, useRC)           
            % GETSEGMENTS Identify segments through depth-first search

            % T is a table of events: when each node is first and last
            % encountered. 'finishnode' will list the nodes per segment.
            % For lack of a better method, using 'discovernode' to break up
            % the finishnode list into segments.
            T = dfsearch(obj.G, 1,...
                {'discovernode', 'finishnode'},...
                'Restart', true);
            
            % What is it called to split a tree into segments of degree=2?
            % Optimize this all later...
            openSegment = false;
            segments = cell(0,1);
            nodeList = [];
            for i = 1:height(T)
                if strcmp(char(T{i,'Event'}), 'discovernode')
                    if openSegment
                        segments = cat(1, segments, {nodeList});
                        nodeList = [];
                        openSegment = false;
                    end
                elseif strcmp(char(T{i, 'Event'}), 'finishnode')
                    if ~openSegment
                        nodeList = [];
                        openSegment = true;
                    end
                    nodeList = cat(1, nodeList, T{i, 'Node'});
                end
            end
            % Close out last segment
            if openSegment
                segments = cat(1, segments, {nodeList});
            end
            
            disp(['Found ' num2str(numel(segments)), ' segments']);
            
            % Connect each segment back to the parent node
            for i = 1:numel(segments)
                IDs = segments{i};
                if numel(IDs) == 1
                    parentNode = obj.G.neighbors(IDs);                    
                else
                    lastNode = IDs(end);
                    pentultNode = IDs(end-1);
                    neighborNodes = obj.G.neighbors(lastNode);
                    parentNode = neighborNodes(neighborNodes ~= pentultNode);
                end
                if ~isempty(parentNode)
                    % Convert back to ID and add to segment
                    segments{i} = cat(1, IDs, parentNode);
                end
            end   
            
            % Get the XYZR for each node
            locations = cell(0,1);
            radii = cell(0,1);
            for i = 1:numel(segments)
                IDs = segments{i};
                xyz = []; r = [];
                for j = 1:numel(IDs)
                    row = find(obj.neuron.nodes.ID == obj.nodeIDs(IDs(j)));
                    xyz = cat(1, xyz, obj.neuron.nodes{row, 'XYZum'});
                    r = cat(1, r, obj.neuron.nodes{row, 'Rum'});
                end
                locations = cat(1, locations, xyz);
                radii = cat(1, radii, r);
            end    
            
            % Convert to cylinder
            X = cell(0,1); Y = cell(0,1);Z = cell(0,1); A = cell(0,1);
            for i = 1:numel(segments)
                if useRC
                    [sx, sy, sz, ang] = obj.rotatedCylinder(...
                        locations{i}', radii{i});
                    A = cat(1, A, ang);
                else
                    [sx, sy, sz] = gencyl(locations{i}', radii{i});
                end
                X = cat(1, X, sx);
                Y = cat(1, Y, sy);
                Z = cat(1, Z, sz);
            end
            if useRC
                segmentTable = table(segments, locations, radii, X, Y, Z, A,...
                    'VariableNames', {'IDs', 'Locations', 'Radii', 'X', 'Y', 'Z', 'A'});
            else
                segmentTable = table(segments, locations, radii, X, Y, Z,...
                    'VariableNames', {'IDs','Locations','Radii', 'X','Y','Z'});
            end
        end
    end
    
    methods (Access = private)
        function [X, Y, Z, A] = rotatedCylinder(obj, locations, radii, bridgePts)
            % ROTATEDCYLINDER  Generates series of rotated cylinders
            % See also: gencyl
            if nargin < 4
                bridgePts = 2;
            end
            
            N = numel(radii);

            D = diff(locations , 1 , 2 );
            L = sqrt(sum(D.^2));
            
            % Interpolate radius 
            if bridgePts > 2
                radii = interp1( 1:N , radii ,...
                    linspace(1,N, bridgePts*(N-1) - (N-2) ) , 'spline' );
            end
                    
            % Axis and angle of rotation for each cylinder
            Qvec = cross( [0;0;1]*ones(1,N-1) , D );
            A = acos(dot([0;0;1]*ones(1,N-1), D)./L);
            
            % Init
            endPt = 0;
            endRadius = 1;
            X = zeros((N-1) * bridgePts, obj.CIRCLEPTS+1);
            Y = zeros((N-1) * bridgePts, obj.CIRCLEPTS+1);
            Z = zeros((N-1) * bridgePts, obj.CIRCLEPTS+1);
            
            for i = 1:(N-1)
                % Start and end indices
                startPt = endPt + 1;
                endPt = i*bridgePts;
                
                % Radius points
                startRadius = endRadius;
                endRadius = startRadius + (bridgePts-1);
                
                % Create matlab cylinder
                [tx, ty, tz] = cylinder(radii(startRadius:endRadius), obj.CIRCLEPTS);
                
                % Get the quaternion rotation matrix
                Q = obj.qrotation(Qvec(:,i), A(i));
                
                % Rotate and scale cylinder
                ty = ty(:)'; tx = tx(:)'; tz = tz(:)';
                C = bsxfun(@plus, Q * vertcat(tx, ty, L(i)*tz),... 
                    locations(:,1));
                
                X(startPt:endPt,:) = reshape(C(1,:)', bridgePts, obj.CIRCLEPTS+1);
                Y(startPt:endPt,:) = reshape(C(2,:)', bridgePts, obj.CIRCLEPTS+1);
                Z(startPt:endPt,:) = reshape(C(3,:)', bridgePts, obj.CIRCLEPTS+1);
            end            
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
    end
end
    
    