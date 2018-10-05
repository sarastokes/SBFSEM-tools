classdef INLBoundary < sbfsem.core.BoundaryMarker
	
	methods
		function obj = INLBoundary(source)
			obj@sbfsem.core.BoundaryMarker(source);
			obj.TYPEID = 224;
            
            obj.update();
            obj.doAnalysis(200);
		end
	end
end