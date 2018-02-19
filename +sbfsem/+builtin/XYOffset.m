classdef XYOffset < sbfsem.core.Transform

	methods
		function obj = XYOffset(source)
			obj@sbfsem.core.Transform();

			source = validateSource(source);
			obj.name = ['XY_OFFSET_', upper(source)];

			obj.filePath = [obj.getDataDir, obj.name];
		end

		function apply(obj, x, y, z)
			% APPLY
			% Uses Z as lookup for transform to apply to XY


			T = dlmread(obj.filePath);

			x = x + T(z, 2);
			y = y + T(z, 3);
		end

		function reverse(obj, data)
			% REVERSE
			T = dlmread(obj.filePath);
		end
	end
end