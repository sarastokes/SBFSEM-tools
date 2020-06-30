classdef NeuronListIterator < Iterator
    %NEURONLISTITERATOR
    %
    % Description:
    %   Traverse a NeuronList
    %
    % Constructor:
    %   obj = NEURONLISTITERATOR(obj)
    %
    % Properties:
    %   loc                 Location of the traversal
    % Inherited properties:
    %   collection          NeuronList(s)
    %
    % Methods:
    %   neuron = next(obj)  Advance to next in list
    %   tf = hasNext(obj)   Check whether there's another element in traversal
    %   reset(obj)          Reset iterator to first element in collection
    %
    % See also:
    %	ITERATOR, SBFSEM.CORE.NEURONLIST, SBFSEM.NEURON, SBFSEM.NEURON
    %
    % History:
    %	4Jan2017 - SSP
    % -------------------------------------------------------------------------
    
    properties
        loc 		% Location of the traversal
    end
    
    methods
        function obj = NeuronListIterator(neuronList)
            if nargin == 0
                % Store reference to empty list by default
                obj.collection = sbfsem.core.NeuronList();
            end
            if isa(neuronList, 'sbfsem.NeuronGroup')
                obj.collection = neuronList.neurons;
            elseif isa(neuronList, 'sbfsem.core.NeuronList')
                obj.collection = neuronList;
            end
            obj.loc = 1;
        end
        
        function elts = next(obj)
            % NEXT  Advance to the next element in sequence and return it
            elts = cell(size(obj));
            
            % Query list for next element
            if obj.hasNext
                % Retrieve the next element
                elts = obj.collection.getn(obj.loc);
                obj.loc = obj.loc + 1;
            end
        end
        
        function next = hasNext(obj)
            % Check if there is another element in the traversal
            next = obj.loc <= obj.collection.length();
        end
        
        function reset(obj)
            obj.loc = 1;
        end
    end
end
