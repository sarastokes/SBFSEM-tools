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

	properties (Dependent = true, Transient = true, Hidden = true)
        offEdges    % Unfinished branches
        terminals   % Branch endings
 	end

	methods
		function obj = StructureAPI()
			% Maybe add link to Neuron factory later
		end

        function xyz = id2xyz(obj, IDs)
            row = ismember(obj.nodes.ID, IDs);
            xyz = obj.nodes{row, 'XYZum'};
        end

        function checkGeometries(obj)
            % CHECKGEOMETRIES  
            %   If geometries are missing but exist, import them
            %   Should be specified by subclasses
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

            if ~isempty(obj.model)
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
            else
                warning('No model - use BUILD function first');
            end
        end
    end
end