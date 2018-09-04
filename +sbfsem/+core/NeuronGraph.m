classdef NeuronGraph < handle
    % NEURONGRAPH
    %
    % Description:
    %   NeuronGraph wraps Matlab's builtin graph data structure
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
    %   nodes           Returns graph nodes
    %   edges           Returns graph edges
    %
    % Methods:
    %   obj.setDirected(isDirected)     Switch between graph and digraph
    %   ID = obj.node2id(nodeID)        Graph node ID to location ID
    %   nodeID = obj.id2node(ID)        Location ID to node ID
    % 	xyz = obj.node2xyz(nodeID)		NodeID to xyz coordinates (um)
    %	xyz = obj.id2xyz(ID)			Location ID to xyz coordinates (um)
    %	M = obj.adjacency() 			Adjacency matrix
    %	M = obj.incidence()				Incidence matrix
    %	M = obj.laplacian()				Laplacian  matrix
    %   v = obj.dfsearch(varargin)      Depth-first search
    %   v = obj.bfsearch(varargin)      Breath-first search
    %
    % History:
    %   16Jan2018 - SSP
    % ---------------------------------------------------------------------
    
	properties (SetAccess = private)
		G
        neuron
        nodeIDs
        isDirected
	end

	properties (Dependent = true, Hidden = true)
		nodes
		edges
	end

	methods
		function obj = NeuronGraph(neuron, isDirected)
			assert(isa(neuron, 'NeuronAPI'), 'Input neuron object');
			if nargin < 2
				obj.isDirected = true;
			else
				assert(islogical(isDirected), 'isDirected is true/false');
				obj.isDirected = isDirected;
			end
            isDirected = true;
            [obj.G, obj.nodeIDs] = graph(neuron, 'directed', isDirected);
		end

		function setIsDirected(obj, isDirected)
            % SETDIRECTED  Switch between graph and digraph
            
			assert(islogical(isDirected));
			obj.isDirected = isDirected;
            % Update the graph
			[obj.G, obj.nodeIDs] = graph(obj.neuron);
		end

		function nodes = get.nodes(obj)
			nodes = obj.G.nodes;
		end

		function edges = get.edges(obj)
			edges = obj.G.edges;
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

        % Useful graph functions
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

        function h = plot(obj, varargin)
        	h = plot(obj.G, varargin{:});
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