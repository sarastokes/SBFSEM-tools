classdef NeuronGraph < handle
    % NEURONGRAPH
    %
    % Description:
    %   NeuronGraph wraps Matlab's builtin graph data structure and
    %   includes additional methods for sbfsem-tools
    %
    % Constructor:
    %   obj = sbfsem.core.NeuronGraph(NEURON, ISDIRECTED)
    %
    % Inputs:
    %   neuron          Neuron object
    % Optional inputs:
    %   isDirected      Digraph or graph (bool, default = true)
    %
    % Properties:
    %   graph           Matlab graph object
    %   neuron          Neuron object
    %   nodeIDs         Array mapping node ID to annotation location ID
    %   isDirected      Directed or undirected graph
    %
    % Dependent properties:
    %   Nodes           Returns graph nodes
    %   Edges           Returns graph edges
    %
    % Methods:
    %   obj.setDirected(isDirected)     Switch between graph and digraph
    %   ID = obj.node2id(nodeID)        Graph node ID to location ID
    %   nodeID = obj.id2node(ID)        Location ID to node ID
    % 	xyz = obj.node2xyz(nodeID)		NodeID to xyz coordinates (um)
    %	xyz = obj.id2xyz(ID)			Location ID to xyz coordinates (um)
    %
    % Methods adding options to Matlab's methods:
    %   p = obj.plot()                  graph/plot, w/ option to set XYZ
    %   p = obj.degreePlot()            Plot and color nodes by degree
    %
    % Methods from Matlab's graph/digraph:
    %	M = obj.adjacency() 			Adjacency matrix
    %	M = obj.incidence()				Incidence matrix
    %	M = obj.laplacian()				Laplacian  matrix
    %   v = obj.dfsearch(varargin)      Depth-first search
    %   v = obj.bfsearch(varargin)      Breath-first search
    %
    % History:
    %   16Jan2018 - SSP
    %   20Aug2019 - SSP - cleaned for implementation
    % ---------------------------------------------------------------------
    
	properties (SetAccess = private)
		G
        neuron
        nodeIDs
        isDirected
	end

	properties (Dependent = true)
		Nodes
		Edges
	end

	methods
		function obj = NeuronGraph(neuron, isDirected)
			assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
                'Input a StructureAPI object');
			if nargin < 2
				obj.isDirected = true;
			else
				assert(islogical(isDirected), 'isDirected is true/false');
				obj.isDirected = isDirected;
			end
            isDirected = true;
            [obj.G, obj.nodeIDs] = neuron.graph('directed', isDirected);
		end

		function setIsDirected(obj, isDirected)
            % SETDIRECTED  Switch between graph and digraph
            
			assert(islogical(isDirected));
			obj.isDirected = isDirected;

            % Update the graph
			[obj.G, obj.nodeIDs] = obj.neuron.graph();
		end

		function nodes = get.Nodes(obj)
			nodes = obj.G.Nodes;
		end

		function edges = get.Edges(obj)
			edges = obj.G.Edges;
        end

        % Access functions
        function id = node2id(node)
        	% NODE2ID  Get graph node from locationID
        	id = obj.nodeIDs(node);
        end
        
        function xyz = id2xyz(id)
            % IDTOXYZ  Get XYZ in microns from locationID
            xyz = obj.neuron.nodes{obj.neuron.nodes.ID == id, 'XYZum'};
        end
        
        function node = id2node(id)
            % ID2NODE  Get node ID from location ID
            node = find(obj.nodeIDs == id);
        end

        function xyz = node2xyz(node)
        	% NODE2XYZ  Get XYZ location of graph node
        	id = obj.node2id(node);
        	xyz = obj.id2xyz(id);
        end
    end

    % Methods from Matlab's graph functions w/ sbfsem-tools add-ons 
    methods
        function p = plot(obj, varargin)
            % PLOT  Plot the graph
            %
            % Optional key/value inputs:
            %   XYZ         Set nodes to annotation XYZ locations
            %               (default = false)
            % -------------------------------------------------------------

            ip = inputParser();
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'XYZ', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.XYZ
                % p = neuronGraphPlot(obj.neuron, ip.Unmatched);
                try
                    p = plot(obj.G, 'layout', 'force3', ip.Unmatched);
                    xyz = [];
                    for i = 1:numel(obj.nodeIDs)
                        iXYZ = obj.node2xyz(obj.nodeIDs(i));
                        if isempty(iXYZ)
                            iXYZ = [0, 0, 0];
                        end
                        xyz = cat(1, xyz, iXYZ);
                    end
                    p.XData = xyz(:, 1); p.YData = xyz(:, 2); p.ZData = xyz(:, 3);
                    hold on; grid on; axis equal tight;
                catch
                    p = plot(obj.G, 'layout', 'layered', ip.Unmatched);
                end
            else
                p = plot(obj.G, ip.Unmatched);
            end
        end

        function p = degreePlot(obj, varargin)
            % DEGREEPLOT  Plot graph with nodes colored by degree
            %
            % Inputs are the same as NeuronGraph/plot
            % -------------------------------------------------------------

            p = obj.plot(varargin{:});

            highlight(p, find(G.degree == 1), 'NodeColor', 'g', 'MarkerSize', 1);
            highlight(p, find(G.degree == 2), 'MarkerSize', 0.05);
            highlight(p, find(G.degree == 3), 'MarkerSize', 1, 'NodeColor', 'r');
        end
    end

    % Useful Matlab graph functions
    methods
        function mat = adjacency(obj)
        	% ADJACENCY  Get adjacency matrix
        	mat = adjacency(obj.G);
        end

        function mat = laplacian(obj)
        	% LAPLACIAN  Get Laplacian matrix
        	if obj.isDirected
        		warning('Laplacian is only for undirected graphs');
        		return;
        	else
        		mat = laplacian(obj.G);
        	end
        end

        function mat = incidence(obj)
        	% INCIDENCE  Get incidence matrix
        	mat = incidence(obj.G);
        end
        
        function T = bfsearch(obj, varargin)
            % BFSEARCH  Breadth-first search
            T = bfsearch(obj.G, varargin{:});
        end

        function T = dfsearch(obj, varargin)
            % DFSEARCH  Depth-first search
        	T = dfsearch(obj.G, varargin{:});
        end
    end
end