classdef NeuronList < List
    % NEURONLIST
    %
    % Description:
    %   A class to abstract functions on a group of neurons
    %
    % Constructor:
    %   obj = NeuronList(neurons, source);
    %
    % Inputs:
    %   neurons                     Array of neurons or vector of cell IDs
    %   source                      Volume name (if providing cell IDs)
    %
    % Properties:
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
    %   elt = getn(obj, n)          Get neuron by position in list
    %	n = length(obj)				Number of neurons
    %	tf = isempty(obj)			Whether list is empty
    %	tf = ismember(obj,ID)		Whether list contains IDs
    %	loc = locationsOf(obj, ID)	Linear index of neuron by ID
    %
    % Notes:
    %   New neurons can be specified as ID numbers or Neurons
    %
    % History:
    %   6Dec2017 - SSP
    %   4Jan2017 - SSP - Added GETN to retrieve by position in list
    % ---------------------------------------------------------------------
    
    % Examples:
    %{
        % Input a list of cell IDs and the source
        h1hc = sbfsem.NeuronList([28 447 619], 'i');
    
        % Input existing neurons, no source needed
        c28 = Neuron(28, 'i');
        c447 = Neuron(417, 'i');
        c619 = Neuron(619, 'i');
        h1hc = sbfsem.core.NeuronList([c28, c447, c619]);
    %}
    
    properties (Access = private)
        list
        idMap
        source
    end
    
    methods (Access = public)
        function obj = NeuronList(neurons, source)
            if nargin == 2
                % If input is cell IDs, source must be included
                obj.source = validateSource(source);
                obj.list = obj.parseInput(neurons);
            else
                % Source can be retrieved from existing neurons
                [obj.list, obj.source] = obj.parseInput(neurons);
            end
            
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
        
        function elts = getn(obj, ind)
            % GETN  Return neuron by position in list
            elts = obj.list(ind);
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
            disp(obj.idMap');
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
        function [neurons, source] = parseInput(obj, elts)
            if isa(elts, 'sbfsem.core.StructureAPI')
                neurons = elts;
                source = elts.source;
            elseif isa(elts, 'sbfsem.NeuronGroup')
                neurons = elts.neurons;
                source = elts.source;
            elseif isnumeric(elts)
                disp('Retriving elements from OData');
                source = obj.source;
                neurons = [];
                for i = 1:numel(elts)
                    neurons = cat(1, neurons,...
                        Neuron(elts(i), obj.source));
                end
            end
        end
    end
end