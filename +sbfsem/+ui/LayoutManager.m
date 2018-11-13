classdef LayoutManager < handle
	
	methods (Static)

		function [h, p] = verticalBoxWithLabel(parentHandle, str, varargin)
			% VERTICALBOXWITHLABEL

			p = uix.VBox('Parent', parentHandle,...
				'BackgroundColor', 'w');
			h = uicontrol(p, 'Style', 'text', 'String', str);
			uicontrol(p, varargin{:});
			set(p, 'Heights', [-0.75, -1]);
        end
        
        function [h, p] = horizontalBoxWithLabel(parentHandle, str, varargin)
            p = uix.HBox('Parent', parentHandle,...
                'BackgroundColor', 'w');
            h = uicontrol(p, 'Style', 'text', 'String', str);
            uicontrol(p, varargin{:});
            set(p, 'Widths', [-1, -1]);
        end
	end
end
