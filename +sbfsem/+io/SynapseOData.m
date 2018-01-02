classdef SynapseOData < sbfsem.io.OData
% SYNAPSEODATA
%
% Inputs:
%	
% ---------------------------------------------------------------------

	properties (SetAccess = private, GetAccess = public)
		parentID
		
		numChildren = 0;
		
		synapses
		nodes
		edges
	end

	properties (Access = private)
		childURL
	end

	methods
		function obj = SynapseOData(source, ParentID)
			obj@sbfsem.io.OData(source);
			obj.parentID = ParentID;

			obj.childURL = [obj.baseURL, 'Structures(',... 
				num2str(obj.parentID), ')/Children',...
				'?$select=ID,TypeID,Tags,ParentID,Label'];
		end

		function pull(obj)
			% PULL  Collect all the data

			obj.getChildNodes();
		end

		function fetchSynapses(obj, expandSynapses)
            % GETSYNAPSES  Fetch children structures
            %
            % Inputs:
            %   expandSynapses      [true] fetch child nodes and edges too
            if nargin < 2
                expandSynapses = true;
            else
                assert(islogical(expandSynapses),...
                    'expandSynapses is a t/f variable');
            end
            
            obj.childData = obj.fetchChildData(expandSynapses);			
		end

        function childNodes = getChildNodes(obj)
            % GETCHILDNODES  Returns synapse nodes as table

            if isempty(obj.childData.nodes)
                obj.fetchSynapses(true);
            end
            
            if isempty(obj.childData.nodes)
                childNodes = [];
            else
                childNodes = array2table(obj.childData.nodes);
                childNodes.Properties.VariableNames = obj.NODENAMES;
            end
        end

        function childEdges = getChildEdges(obj)
            % GETCHILDEDGES  Returns synapse links as table
            
            if isempty(obj.childData.edges)
                obj.fetchSynapses(true);
            end
            
            if isempty(obj.childData.edges)
                childEdges = [];
            else
                childEdges = array2table(obj.childData.edges);
                childEdges.Properties.VariableNames = obj.EDGENAMES;
            end
        end
	end

	methods (Access = private)
		function childData = fetchChildData(obj, expandChild)
			% FETCHCHILDDATA  Returns child data
			childURL = getODataURL(obj.ID, obj.source, 'child');
		end

        function Locs = processChildLocation(obj, ID)
            % PROCESSCHILDLOCATION  Fetch synapse location with error check
            
            locationURL = getODataURL(ID, obj.source, 'location');
            importedData = readOData(locationURL);
            if ~isempty(importedData.value)
                Locs = obj.processLocationData(importedData.value);
            else
                Locs = NaN;
                % This is important to track bc throws errors in VikingPlot
                fprintf('No locations for s%u\n', ID);
            end
        end 

        function [childLocs, childLinks, nullIDs] = expandChildData(obj, IDs)
            % EXPANDCHILDDATA  Returns nodes and edges for child structures
            
            nullIDs = []; % Tracks IDs without location data
            childLocs = []; 
            childLinks = [];
            for i = 1:numel(IDs)
                locs = obj.processChildLocation(IDs(i));
                if isnan(locs)
                    nullIDs = [nullIDs, IDs(i)]; %#ok
                else % If valid, add to child locations and fetch links
                    childLocs = cat(1, childLocs, locs);
                    links = obj.fetchLinkData(IDs(i));
                    if ~isempty(links)
                        childLinks = cat(1, childLinks, links);
                    end
                end
            end
        end
    end 

	methods (Access = private)
		function setupSynapses(obj)
			% SETUPSYNAPSES  Parse into sbfsem-tools variables

			import sbfsem.core.StructureTypes;
			% Init temporary variables to track nodes per synapse structure
			numSynapseNodes = [];
			for i = 1:height(obj.synapses)
				% Find the nodes associated with the synapse
				row = find(obj.nodes.ParentID == obj.synapses.ID(i));
				numSynapseNodes = cat(1, numSynapseNodes, numel(row));
				% Mark unique synapses, these will be plotted
				if numel(row) > 1
					% Get the median annotation (along the Z-axis)
					% TODO: decide if this is best approach
					ind = find(obj.nodes.Z(row,:) == floor(median(obj.nodes.Z(row,:))));
					obj.nodes.Unique(row(ind), :) = 1; %#ok
				elseif numel(row) == 1
					obj.nodes.Unique(row,:) = 1;
				end					
			end
			obj.synapses.N = numSynapseNodes;
		end

		function setStructureType(obj)
			% SETSTRUCTURETYPES  Match to TypeID the Viking StructureType

			structures = sbfsem.core.VikingStructureTypes(obj.synapses.TypeID);
			% Match to local StructureType
			localNames = cell(numel(structures), 1);
			for i = 1:numel(structures)
				localNames{i,:} = sbfsem.core.StructureTypes.fromViking(...
					structures(i), obj.synapses.Tag{i,:});
			end
			obj.synapses.LocalName = localNames;
			% Make sure synapses match the new naming conventions
			makeConsistent(obj);
		end
	end
end