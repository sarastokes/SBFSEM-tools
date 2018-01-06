classdef ConeOData < sbfsem.io.OData
%CONEODATA
% 
% Description:
%   Import cone outlines from OData
% 
% Constructor:
%   obj = ConeOData(source);
%
% Methods
%   IDs = obj.getConeIDs(coneType);
%
% History
%   5Jan2017 - SSP
% -------------------------------------------------------------------------
    properties (Constant = true, Hidden = true)
        CONES = {'LM', 'S'};
    end
    
	methods
		function obj = ConeOData(source)
			obj@sbfsem.io.OData(source)
		end

		function IDs = getConeIDs(obj, coneType)
			IDs = fetchConeIDs(obj, coneType);
		end
	end

	methods (Access = private)
		function IDs = fetchConeIDs(obj, coneType)
			coneStr = [coneType, 'TRACE'];
			data = readOData([getServiceRoot(obj.source),...
				'Structures?$filter=contains(Label, ''',...
				coneStr, ''')&$select=ID']);
			IDs = struct2array(data.value);
		end
	end
end