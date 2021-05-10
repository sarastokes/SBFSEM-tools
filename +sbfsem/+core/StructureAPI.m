classdef (Abstract) StructureAPI < handle
% STRUCTUREAPI  Parent class for all Structure objects

	properties (SetAccess = protected, GetAccess = public)
        % Cell ID in Viking
        ID
        % Volume cell exists in
        source
        % Neuron's data from Viking
        viking
        % Table of each location ID
        nodes
        % Table of the links between annotations
        edges
        % Volume dimensions (nm per pixel)
        volumeScale
        % Closed curve geometries
        geometries
        % Date info pulled from odata
        lastModified
        % Analyses related to the neuron
        analysis = containers.Map();
        % Omitted location IDs
        omittedIDs = [];
        % Transform applied	
        transform = [];
        % Any notes in neuron's data from Viking
        notes = [];
    end
    
    properties (Access = public)
        % Render of neuron
        model = [];
    end

	properties (Dependent = true, Hidden = true)
        offEdges    % Branches running off volume edges
        terminals   % Branch endings
        unfinished  % Unfinished branches
 	end

    properties (Access = private, Transient = true, Hidden = true)
        ODataClient
        GeometryClient
    end

	methods
		function obj = StructureAPI(ID, source)
            if nargin == 1
                source = ID{2};
                ID = ID{1};
            end
            validateattributes(ID, {'numeric'}, {'numel', 1});
            obj.ID = ID;
            obj.source = validateSource(source);
            
            try
                obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);
                % XYZ volume dimensions in nm/pix, nm/pix, nm/sections
                obj.volumeScale = getODataScale(obj.source);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:webservices:UnknownHost')
                    fprintf('Operating in offline mode\n');
                end
                obj.ODataClient = [];
                obj.volumeScale = loadCachedVolumeScale(obj.source);
            end

            % Track when the object was created
            obj.lastModified = datestr(now);
		end

        function update(obj)
            % UPDATE  Updates existing OData
            % Modify in subclasses to include child structures
            obj.pull();
            obj.lastModified = datestr(now);
        end
        
        function ID = getLastModifiedID(obj)
            % GETLASTMODIFIEDID  Get last modified location ID in structure
            data = getLastModifiedAnnotation(obj.ID, obj.source);
            ID = data.ID;
        end

        function xyz = id2xyz(obj, IDs)
            row = ismember(obj.nodes.ID, IDs);
            xyz = obj.nodes{row, 'XYZum'};
        end
    end

    methods (Access = protected)
        function xyz = getXYZbyParent(obj, parentID, useMicrons)
            if nargin < 3
                useMicrons = true;
            end
            
            row = obj.nodes.ParentID == parentID;

            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y', 'Z'}};
            end
        end

        function cellNodes = getNodesByParent(obj, parentID)
            row = obj.nodes.ParentID == parentID;
            cellNodes = obj.nodes(row, :);
        end
    end

    % Closed curve methods
    methods
        function getGeometries(obj)
            % GETGEOMETRIES  Import ClosedCurve-related OData
            if isempty(obj.GeometryClient)
                obj.GeometryClient = sbfsem.io.GeometryOData(obj.ID, obj.source);
            end
            obj.geometries = obj.GeometryClient.pull();
        end

        function checkGeometries(obj)
            % CHECKGEOMETRIES   Try to import geometries, if missing
            if isempty(obj.geometries)
                obj.getGeometries();
            end
        end
    end

    % Cell annotation methods
    methods
    	function offEdges = get.offEdges(obj)
    		if ismember('OffEdge', obj.nodes.Properties.VariableNames)
    			rows = obj.nodes.OffEdge == 1;
    			offEdges = obj.nodes(rows, :).ID;
    		else
    			offEdges = [];
    		end
    	end 

    	function terminals = get.terminals(obj)
    		if ismember('Terminal', obj.nodes.Properties.VariableNames)
    			rows = obj.nodes.Terminal == 1;
    			terminals = obj.nodes(rows, :).ID;
    		else
    			terminals = [];
    		end
        end
        
        function unfinished = get.unfinished(obj)
            [G, nodeIDs] = obj.graph();
            unfinished = nodeIDs(G.degree == 1);
            unfinished = setdiff(unfinished, obj.terminals);
            unfinished = setdiff(unfinished, obj.offEdges);
        end

        function edgeIDs = getEdgeNodes(obj)
            if isempty(obj.terminals) || isempty(obj.offEdges)
                edgeIDs = [];
            else
                edgeIDs = intersect(obj.terminals, obj.offEdges);
            end
        end

        function xyz = getCellXYZ(obj, useMicrons)
            % GETCELLXYZ  Returns cell body coordinates
            %
            %   Inputs:     useMicrons  [t]  units = microns or volume
            % ----------------------------------------------------------
            if nargin < 2
                useMicrons = true;
            end

            xyz = obj.getXYZbyParent(obj.ID, useMicrons);
        end

        function cellNodes = getCellNodes(obj)
            % GETCELLNODES  Return only cell body nodes

            cellNodes = obj.getNodesByParent(obj.ID);
        end
 	end


	% Graph theory methods
	methods
        function [G, nodeIDs] = graph(obj, varargin)
            % NEURON2GRAPH  Create a graph representation
            %
            % Optional key/value inputs:
            %   directed      [false]   Directed graph?
            %   weighted      [false]   Weight edges by distance b/w nodes?
            %   synapses      [false]   Include child structures?
            %   visualize     [false]   Plot the graph?
            %
            % Outputs:
            %   G               graph or digraph
            %   nodesIDs        array (ith entry is loc ID of node i)
            % -------------------------------------------------------------

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'Directed', false, @islogical);
            addParameter(ip, 'Weighted', false, @islogical);
            addParameter(ip, 'Synapses', false, @islogical);
            addParameter(ip, 'Visualize', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.Synapses
                ind = obj.edges;
            else
                ind = obj.edges.ID == obj.ID;
            end
            
            A = string(obj.edges.A(ind));
            B = string(obj.edges.B(ind));

            if ip.Results.Directed
                G = digraph(A, B);
            else
                G = graph(A, B);
                if ip.Results.Weighted
                    G = graph(A, B, getEdgeWeights(obj));
                end
            end

            if ip.Results.Visualize
                figure();
                plot(G);
            end

            % Lookup table for locationIDs of nodes where ith entry is
            % the location ID of node i.
            nodeIDs = str2double(G.Nodes{:,:});

            % Remove any omitted nodes from the graph
            if ~isempty(obj.omittedIDs)
                for i = 1:numel(obj.omittedIDs)
                    G = G.rmnode(find(nodeIDs == obj.omittedIDs(i))); %#ok
                    nodeIDs = str2double(G.Nodes{:,:});
                end
                fprintf('Omitted %u locations\n', numel(obj.omittedIDs));
            end
            
            function edgeWeights = getEdgeWeights(neuron)
                aXYZ = []; bXYZ = [];
                for j = 1:numel(neuron.edges.A)
                    aXYZ = cat(1, aXYZ, neuron.id2xyz(neuron.edges.A(j)));
                    bXYZ = cat(1, bXYZ, neuron.id2xyz(neuron.edges.B(j)));
                end
                edgeWeights = fastEuclid3d(aXYZ, bXYZ);
            end
        end

        function nodes = getBranchNodes(obj, locationA, locationB, verbose)
            % GETBRANCHNODES 
            if nargin < 4
                verbose = false;
            end
            
            [G, nodeIDs] = graph(obj, 'directed', false);

            % Convert from location ID to graph's node ID
            nodeA = find(nodeIDs == locationA);
            nodeB = find(nodeIDs == locationB);

            % Get the path between the nodes
            nodePath = shortestpath(G, nodeA, nodeB);

            % Misconnected nodes are common, check for them
            if isempty(nodePath)
                error('Location IDs %u and %u are not connected!',... 
                    locationA, locationB);
            end
            if verbose
                fprintf('Analyzing a %u node path between %u and %u\n',...
                    numel(nodePath), locationA, locationB);
            end

            % Convert back from the graph's node IDs to location ID
            locationIDs = nodeIDs(nodePath);

            % Return only the nodes along that path
            [~, ~, ind] = intersect(locationIDs, obj.nodes.ID, 'stable');
            nodes = obj.nodes(ind, :);
        end
        
        function p = gplot(obj, varargin)
            % GPLOT
            %   Wrapper for neuronGraphPlot
            % Inputs: (see neuronGraphPlot's inputs)
            % -------------------------------------------------------------
            p = neuronGraphPlot(obj, varargin{:});
            
        end
    end

	% Rendering methods
	methods
        function xyz = getDAspect(obj, ax)
            % GETDASPECT
            %   Scales a plot by x,y,z dimensions
            % Optional inputs:
            %   ax      axesHandle to apply daspect
            % -------------------------------------------------------------
            % xyz = obj.volumeScale/max(abs(obj.volumeScale));
            xyz = max(obj.volumeScale)./obj.volumeScale;
            if nargin == 2
                assert(isa(ax, 'matlab.graphics.axis.Axes'),...
                    'Input an axes handle');
                daspect(ax, xyz);
            end
        end

        function model = build(obj, renderType, varargin)
            % BUILD  Quick access to render methods
            %
            % Inputs:
            %   renderType      'cylinder' (default), 'closedcurve', 'disc'
            %   varargin        Input to render function
            % Output:
            %   model           render object (also stored in properties)
            %--------------------------------------------------------------
            if nargin < 2
                renderType = 'cylinder';
            end

            if ~isempty(obj.model)
                obj.model = [];
            end

            switch lower(renderType)
                case {'cylinder', 'cyl'}
                    model = sbfsem.render.Cylinder(obj, varargin{:});
                case {'closedcurve', 'cc', 'curve'}
                    model = renderClosedCurve(obj, varargin{:});
                case {'outline'}
                    model = sbfsem.builtin.ClosedCurve(obj);
                case 'disc'
                    model = sbfsem.render.Disc(obj, varargin{:});
                otherwise
                    warning('Render type %s not found', renderType);
                    return;
            end
            obj.model = model;
        end

        function dae(obj, fName)
            % DAE  Export model as COLLADA file
            %
            % Inputs:
            %   fName       filename (char)
            %
            % See also:
            %   EXPORTSCENEDAE
            % -------------------------------------------------------------
            if isempty(obj.model)
                obj.build();
            elseif isnumeric(obj.model) || isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                warning('Model must be a Cylinder render, use exportSceneDAE');
                return;
            end

            if nargin < 2
                obj.model.dae();
            else
                obj.model.dae(fName);
            end
        end

        function p = render(obj, varargin)
            % RENDER
            %
            % Inputs:
            %   varargin        See render function inputs
            %
            % See also:
            %   RENDERCLOSEDCURVE, SBFSEM.RENDER.CYLINDER
            % -------------------------------------------------------------

            if isempty(obj.model)
                obj.build();  % Assumes disc annotations
            end
            if isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                obj.model.trace(varargin{:});
                p = [];
            elseif isnumeric(obj.model) % Closed curve volume
                p = volumeRender(obj.model,...
                    'Tag', ['c', num2str(obj.ID)],...
                    varargin{:});
            else
                p = obj.model.render(varargin{:});
            end
        end
    end

    % Post-import processing methods
    methods (Access = protected)
        function pull(obj)
            % PULL  Fetch and parse OData
            
            % Get the relevant data with OData queries
            [obj.viking, obj.nodes, obj.edges] = obj.ODataClient.pull();

            % XY transform and then convert data to microns
            obj.nodes = obj.setXYZum(obj.nodes);

            % Handle closed curve geometries, if necessary
            if nnz(obj.nodes.Geometry == 6)
                obj.getGeometries();
                fprintf('   %u closed curves in c%u\n',...
                    obj.ID, height(obj.geometries));
            end

            % Search for omitted nodes by location ID and section number
            obj.omittedIDs = omitLocations(obj.ID, obj.source);
            omittedSections = omitSections(obj.source);
            if ~isempty(omittedSections)
                for i = 1:numel(omittedSections)
                    row = obj.nodes.Z == omittedSections(i);
                    obj.omittedIDs = [obj.omittedIDs; obj.nodes(row,:).ID];
                end
            end

            % Make notes easily visible with notes property
            obj.notes = obj.viking.Notes;
        end

        function nodes = setXYZum(obj, nodes)
            % SETXYZUM  Convert Viking pixels to microns

            if isempty(nodes)
                return
            end
                        
            % Apply custom transforms, if needed 
            if obj.transform == sbfsem.builtin.Transforms.Custom
                switch obj.source
                    case 'NeitzInferiorMonkey'
                        [X, Y] = obj.transform.translate(...
                            [nodes.X, nodes.Y, nodes.Z], obj.source);
                    case 'NeitzNasalMonkey'
                        [X, Y] = obj.transform.translate(...
                            [nodes.VolumeX, nodes.VolumeY, nodes.Z], obj.source);
                        [X, Y] = obj.transform.nasalMonkey(...
                            [X, Y, nodes.Z], [1320, 1200, 1]);
                end
            else
                X = nodes.VolumeX;
                Y = nodes.VolumeY;
            end

            % Create an XYZ in microns column
            nodes.XYZum = zeros(height(nodes), 3);
            nodes.XYZum = obj.transform.scale([X, Y, nodes.Z], obj.volumeScale);
            % Create a column for radius in microns
            nodes.Rum = obj.transform.scale(nodes.Radius, obj.volumeScale);
            % TODO: There's an assumption about the units in here...
            % Assumes data is in nm and needs to be converted to microns
        end
    end
end