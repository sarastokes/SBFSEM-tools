classdef NeuronList < List
% NEURONLIST 
%
% Properties
%	list 						array of neurons
%	idMap 						index of cell IDs
%	source 						volume name
% Inherited properties:
%	numElts 					number of elements
%
% Methods:
%	add(obj, ID)				Add neuron(s)
%	remove(obj, ID) 			Remove neuron(s)
%	elt = get(obj, ID) 			Get a neuron by ID number
%	n = length(obj)				Number of neurons
%	tf = isempty(obj)			Whether list is empty
%	tf = ismember(obj,ID)		Whether list contains IDs
%	loc = locationsOf(obj, ID)	Linear index of neuron by ID
% 
% New neurons can be specified as ID, Neuron or NeuronGroup
% 6Dec2017 - SSP

	properties (Access = private)
		list
		idMap
        source
	end

	methods (Access = public)
		function obj = NeuronList(neurons, source)
			if nargin == 2
				obj.source = validateSource(source);
			else
				obj.source = [];
			end
			[obj.list, obj.source] = obj.parseInput(neurons);

			obj.idMap = arrayfun(@(x) x.ID, obj.list);
		end

		function numElts = length(obj)
			% LENGTH  Return number of neurons in list
			numElts = numel(obj.list);
		end

		function empty = isempty(obj)
			% ISEMPTY  Return whether list is empty
			empty = isempty(obj.list);
		end

		function add(varargin)
			% ADD  Append a neuron to end of list
			obj = varargin{1};
			elts = obj.parseInput(varargin{2});

			newIDs = arrayfun(@(x) x.ID, elts);
			if ismember(newIDs, obj.idMap)
				error('MATLAB:List:NeuronList - ID already exists');
				% TODO: resolve this
			end

			obj.list = cat(1, obj.list, elts);
			obj.idMap = cat(1, obj.idMap, newIDs);
		end

		function elts = get(obj, IDs)
			% GET  Return neuron by ID number
			locs = obj.locationsOf(IDs);
			elts = obj.list(locs);
		end

		function elts = remove(obj, IDs)
			% REMOVE  Remove neuron by ID number
			locs = obj.locationsOf(IDs);
            elts = obj.list(locs);
            % Remove from list and ID map
			obj.list(locs) = [];
			obj.idMap(locs) = [];           
		end

		function count = countOf(obj, elt) %#ok
			% nah
		end

        function locs = locationsOf(obj, IDs)
        	% LOCATIONSOF  Get linear index from ID number
			[locs, elts] = find(bsxfun(@eq, obj.idMap, IDs));
			if numel(elts) < numel(IDs)
				warning('element %u was not found',...
					IDs(setdiff(1:numel(IDs), elts)));
			end
		end

		function locs = ismember(obj, IDs)
			% ISMEMBER  Check whether ID(s) are in list
			locs = intersect(IDs, obj.idMap);
        end
        
        function disp(obj)
        	% DISP  Print the list of IDs to cmd line
            fprintf('NeuronList with %u neurons: \n',...
            	numel(obj.idMap));
            disp(obj.idMap);
        end
    end
    
    methods (Access = public)
        function ids = getIDs(obj)
            ids = obj.idMap;
        end
        
        function setSource(obj, source)
            obj.source = validateSource(source);
        end
    end

	methods (Access = private)
		function loc = id2loc(obj, ID)
			% ID2LOC Find location of a cell ID
			loc = find(obj.idMap == ID);
		end

		function [neurons, source] = parseInput(obj, elts)
			if isa(elts, 'sbfsem.Neuron')
				neurons = elts;
				source = elts.source;
			elseif isa(elts, 'sbfsem.NeuronGroup')
				neurons = elts.neurons;
				source = elts.source;
			elseif isnumeric(elts)
                disp('Retriving elements from OData');
				neurons = [];
				for i = 1:numel(elts)
					neurons = cat(1, neurons,...
						sbfsem.Neuron(elts(i), obj.source));
				end
			end
		end
	end
end