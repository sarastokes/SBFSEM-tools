classdef Network < handle
	% NETWORK
    %
    % Constructor:
    %   obj = Network(ID, source)
    %
    % Inputs:
    %   ID          Neuron ID to form network around
    %   source      Volume name or abbreviation
    %
    % History:
    %   25Mar2018 - SSP
    % ---------------------------------------------------------------------
	properties (SetAccess = private)
		ID
		source
		
		idMap
		sourceMap
		targetMap
		weightMap
		synapseMap
        directionMap

		omittedLinks
	end

	properties (Transient = true, Hidden = true)
		NetworkClient
	end


	methods
		function obj = Network(ID, source)
            obj.source = validateSource(source);
            obj.ID = ID;

            obj.pull();
		end

		function G = synapseGraph(obj, synapseName, isDirected)

			if nargin < 3
				isDirected = true;
			end

			ind = cellfun(@(x) strcmp(x, synapseName), obj.synapseMap);
			if nnz(ind) == 0
				error('No examples of synapse %s found!', synapseName);
			end

			sources = obj.sourceMap(ind);
			targets = obj.targetMap(ind);
			links = obj.weightMap(ind);

			if isDirected
				G = digraph(sources, targets, links);
			else
				G = graph(sources, targets, links);
			end
		end

		function forAndrea(obj)
			% Display synapses with multiple links
			for i = 2:max(obj.weightMap)
				n = find(obj.weightMap == i);
				if nnz(n) == 0
					fprintf('No instances of %u links\n', i);
				else
					fprintf('Returning synapses with %u links\n', i);
					for j = 1:numel(n)
						fprintf('\t%u %s synapses between %u and %u\n',...
							i, obj.synapseMap{j}, obj.sourceMap(j), obj.targetMap(j));
					end
				end
			end
		end

        function nodeID = id2node(obj, ID)
            % ID2NODE  Get the node ID from structure ID
            nodeID = find(obj.idMap == ID);
        end
        
        function ID = node2id(obj, nodeID)
            % NODE2ID  Get the structure ID from the node ID
            ID = obj.idMap(nodeID);
        end
	end

	methods (Access = private)
		function pull(obj)
			disp('Querying database...');
			obj.NetworkClient = sbfsem.io.NetworkOData(obj.ID, obj.source);
			data = obj.NetworkClient.pull();

            disp('Parsing results...');
            obj.idMap = cellfun(@(x) x.StructureID, data.nodes);
            obj.sourceMap = cellfun(@(x) x.SourceStructureID, data.edges);
            obj.targetMap = cellfun(@(x) x.TargetStructureID, data.edges);

            % Omit links involving only one structure
            obj.omittedLinks = arrayfun(@isequal, obj.sourceMap, obj.targetMap);
            if nnz(obj.omittedLinks) > 0
				fprintf('\tOmitted %u links\n', nnz(obj.omittedLinks));

    	        data.edges = data.edges(~obj.omittedLinks);
        	    obj.sourceMap(obj.omittedLinks) = [];
            	obj.targetMap(obj.omittedLinks) = [];
            end

            % Parse additional parameters after link omission
            obj.weightMap = cellfun(@(x) numel(x.Links), data.edges);
            obj.synapseMap = cellfun(@(x) x.Type, data.edges,...
            	'UniformOutput', false);
            obj.directionMap = cellfun(@(x) x.Directional, data.edges);
		end
	end
end