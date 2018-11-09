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
        % Render of neuron
        model = [];
        % Omitted location IDs
        omittedIDs = [];
        % Transform applied	
        transform = [];
	end

	properties (Dependent = true, Hidden = true)
        offEdges    % Unfinished branches
        terminals   % Branch endings
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
            
            obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);

            % XYZ volume dimensions in nm/pix, nm/pix, nm/sections
            obj.volumeScale = getODataScale(obj.source);

            % Track when the object was created
            obj.lastModified = datestr(now);
		end

        function update(obj)
            % UPDATE  Updates existing OData
            % Modify in subclasses to include child structures
            obj.pull();
            obj.lastModified = datestr(now);
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
            %   directed        [f]     directed or undirected
            %   synapses        [f]     include child structures
            %   visualize       [f]     plot the graph?
            %
            % Outputs:
            %   G               graph or digraph
            %   nodesIDs        array (ith entry is loc ID of node i)
            % -------------------------------------------------------------

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'directed', false, @islogical);
            addParameter(ip, 'synapses', false, @islogical);
            addParameter(ip, 'visualize', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.synapses
                edge_rows = obj.edges;
            else
                edge_rows = obj.edges.ID == obj.ID;
            end

            if ip.Results.directed
                G = digraph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(deblank(num2str(obj.edges.B(edge_rows,:)))));
            else
                G = graph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(num2str(obj.edges.B(edge_rows,:))));
            end

            if ip.Results.visualize
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
        end
	end

	% Rendering methods
	methods
        function xyz = getDAspect(obj, ax)
            % GETDASPECT
            %   Scales a plot by x,y,z dimensions
            % Optional inputs:
            %   ax      axesHandle to apply daspect
            % ----------------------------------------------------------
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

        function render(obj, varargin)
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
            elseif isnumeric(obj.model) % Closed curve volume
                volumeRender(obj.model,...
                    'Tag', ['c', num2str(obj.ID)],...
                    varargin{:});
            else
                obj.model.render(varargin{:});
                view(3);
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
        end

        function nodes = setXYZum(obj, nodes)
            % SETXYZUM  Convert Viking pixels to microns
            % if nnz(nodes.X) + nnz(nodes.Y) > 2
            %    disp('Estimating synapse locations...');
            %    nodes = estimateSynapseXY(obj, nodes);
            % end
            
            % Apply transforms to NeitzInferiorMonkey
            if isempty(nodes)
                return
            end
            if obj.transform == sbfsem.core.Transforms.SBFSEMTools
                xyDir = [fileparts(fileparts(fileparts(...
                    mfilename('fullpath')))), '\data'];
                xydata = dlmread([xyDir,...
                    '\XY_OFFSET_NEITZINFERIORMONKEY.txt']);
                volX = nodes.X + xydata(nodes.Z,2);
                volY = nodes.Y + xydata(nodes.Z,3);
            else
                volX = nodes.VolumeX;
                volY = nodes.VolumeY;
            end

            % Create an XYZ in microns column
            nodes.XYZum = zeros(height(nodes), 3);
            % TODO: There's an assumption about the units in here...
            nodes.XYZum = bsxfun(@times,...
                [volX, volY, nodes.Z],...
                (obj.volumeScale./1e3));
            % Create a column for radius in microns
            nodes.Rum = nodes.Radius * obj.volumeScale(1)./1000;
        end
    end
end