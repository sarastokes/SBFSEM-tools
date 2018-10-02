classdef VesselAdjacency < sbfsem.core.StructureAPI

	properties (SetAccess = private)
		ParentID  % BloodVessel ID
	end
	
	properties (Constant = true, Hidden = true)
		STRUCTURE = 'Vessel Adjacency'
	end

	methods
		function obj = VesselAdjacency(ID, source, transform)
			obj@sbfsem.core.StructureAPI(ID, source);

			if nargin < 3
				obj.transform = sbfsem.core.Transforms.Viking;
			else
				obj.transform = sbfsem.core.Transforms.fromStr(transform);
			end

			% Instantiate OData client
			obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);

			% Fetch and parse the OData
			obj.pull();
			obj.ParentID = obj.viking.ParentID;
		end
	end
end