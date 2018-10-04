classdef GCLBoundary < sbfsem.core.BoundaryMarker
	

	methods
		function obj = GCLBoundary(source)
			obj@sbfsem.core.BoundaryMarker(source);
			obj.TYPEID = 235;
            
            obj.update();
		end
	end
end