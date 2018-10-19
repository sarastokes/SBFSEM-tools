classdef Vasculature < sbfsem.core.StructureGroup
	
	properties (SetAccess = private)
		vessels
		IDs
	end

	methods
		function obj = Vasculature(source)
			obj@sbfsem.core.StructureGroup(source);

			obj.typeID = 3;
			obj.update();
		end

		function update(obj)
			obj.pull();
        end

		function render(obj, ax, varargin)
			% RENDER  3D render
			% 
			% Optional inputs:
			%	ax 			axes handle (default = new)
			
			if nargin < 2 || isempty(ax)
				ax = axes('Parent', figure());
				hold(ax, 'on');
				grid(ax, 'on');
			end

			for i = 1:numel(obj.IDs)
				obj.vessels(i).render('ax', ax,...
					'FaceColor', hex2rgb('ff4040'),...
                    'Tag', 'BloodVessel');
				drawnow;
			end
		end
	end

	methods (Access = protected)
		function pull(obj)
			% PULL  Get structures through OData query
			pull@sbfsem.core.StructureGroup(obj);

			obj.IDs = obj.queryByTypeID();
            if isempty(obj.IDs)
                fprintf('No blood vessels found for %s\n', obj.source);
                return;
            end

			obj.vessels = {};
			for i = 1:numel(obj.IDs)
                try
                    obj.vessels = cat(1, obj.vessels,...
                        sbfsem.core.BloodVessel(obj.IDs(i), obj.source));
                    obj.vessels(i).build();
                catch 
                    fprintf('Import failed for %u\n', obj.IDs(i));
                end
			end
		end
	end
end