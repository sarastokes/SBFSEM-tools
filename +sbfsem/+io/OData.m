classdef OData < handle

	properties (Access = protected)
		source
		baseURL
	end

	methods
		function obj = OData(source)
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), '\', 'OData\'];
		end
	end
end