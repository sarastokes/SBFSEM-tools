classdef LayoutManager < handle
	
	methods (Static)

		function h = verticalBoxWithLabel(parentHandle, str, varargin)
			% VERTICALBOXWITHLABEL

			h = uix.VBox('Parent', parentHandle,...
				'BackgroundColor', 'w');
			uicontrol(h, 'Style', 'text', 'String', str);
			uicontrol(h, varargin{:});
			set(h, 'Heights', [-0.75, -1]);
        end
        
        function h = horizontalBoxWithLabel(parentHandle, str, varargin)
            h = uix.HBox('Parent', parentHandle,...
                'BackgroundColor', 'w');
            uicontrol(h, 'Style', 'text', 'String', str);
            uicontrol(h, varargin{:});
            set(h, 'Widths', [-1, -1]);
        end
	end
end
