classdef OrganizedSER < sbfsem.core.StructureGroup
	% ORGANIZEDSER
	%
	% In NeitzInferiorMonkey, I use this for laminated bodies
	%
	% History:
	%	5Nov2018 - SSP
	% --------------------------------------------------------------------

	properties
		IDs
		parentIDs
	end

	methods
		function obj = OrganizedSER(source)
			obj@sbfsem.core.StructureGroup(source);

			obj.typeID = 81;
			obj.update();
		end

		function update(obj)
			obj.pull();
		end

		function T = table(obj)
			T = table(obj.IDs, obj.parentIDs,...
				'VariableNames', {'ID', 'ParentID'});
			T = sortrows(T, 'ParentID');
		end

		function T2 = count(obj)
			T = obj.table();
			[groups, groupNames] = findgroups(T.ParentID);
			x = splitapply(@numel, T.ParentID, groups);
			T2 = table(groupNames, x,...
				'VariableNames', {'IDs', 'N'});
			T2 = sortrows(T2, 'N', 'descend');
		end
	end

	methods (Access = protected)
		function pull(obj)
			% PULL  Get structures through OData query
			pull@sbfsem.core.StructureGroup(obj);

			[obj.IDs, obj.parentIDs] = obj.queryByTypeID();
		end
	end
end