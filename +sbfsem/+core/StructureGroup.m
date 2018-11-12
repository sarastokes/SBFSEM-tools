classdef (Abstract) StructureGroup < handle

	properties (SetAccess = private, GetAccess = protected)
		source
		baseURL
	end

	properties (SetAccess = protected)
		typeID
		queryDate
	end

	methods
		function obj = StructureGroup(source)
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), obj.source, '/OData/'];

			obj.typeID = NaN;  % Set in subclass constructors
		end

		function update(obj)
			% UPDATE  Refresh by repeating OData query
			obj.pull();
		end
	end

	methods (Access = protected)
		function [structureIDs, parentIDs] = queryByTypeID(obj)
			% QUERYBYTYPEID  Return structure IDs for a type ID
			if isnan(obj.typeID)
				error('Invalid type ID');
			end
			
			obj.queryDate = datestr(now);
			disp('Querying OData...');

			data = readOData([obj.baseURL,...
				'Structures?$filter=TypeID eq ', num2str(obj.typeID),...
				'&$select=ID,ParentID']);
			value = cat(1, data.value{:});
			structureIDs = vertcat(value.ID);
            parentIDs = vertcat(value.ParentID);
		end

		function pull(obj)
			% PULL  OData query
			% Implemented by subclasses
		end
	end
end