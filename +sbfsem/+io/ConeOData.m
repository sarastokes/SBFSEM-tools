classdef ConeOData < sbfsem.io.OData
% CONEODATA
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
%   5Jan2018 - SSP
%   8Feb2018 - SSP - Added undefined (U) cone type
%   5Mar2018 - SSP - Updated to new JSON decoding
% -------------------------------------------------------------------------
    properties (Constant = true, Hidden = true)
        CONES = {'LM', 'S', 'U'};
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
            value = cat(1, data.value{:});
			IDs = struct2array(value);
		end
	end
end