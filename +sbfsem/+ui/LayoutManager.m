classdef LayoutManager < handle
% LAYOUTMANAGER
%
% Description:
%	Set of methods for common compound user interface components
%
% Syntax:
%	obj = sbfsem.ui.LayoutManager();
%
% History:
%	23Jul2018
%	30Sep2019 - SSP - Added bold label methods
% ------------------------------------------------------------------------
	
	methods (Static)

		function [h, p] = verticalBoxWithLabel(parentHandle, str, varargin)
			% VERTICALBOXWITHLABEL
			%
			% Inputs:
			%	parentHandle 		Where the ui component is initialized
			%	str 				Text for the label
			%	varargin 			Inputs to uicontrol for 2nd component
			% ------------------------------------------------------------

			p = uix.VBox('Parent', parentHandle,...
				'BackgroundColor', 'w');
			h = uicontrol(p, 'Style', 'text', 'String', str);
			uicontrol(p, varargin{:});
			set(p, 'Heights', [-0.75, -1]);
        end
        
		function [h, p] = horizontalBoxWithLabel(parentHandle, str, varargin)
			% HORIZONTALBOXWITHLABEL
            p = uix.HBox('Parent', parentHandle,...
                'BackgroundColor', 'w');
            h = uicontrol(p, 'Style', 'text', 'String', str);
            uicontrol(p, varargin{:});
            set(p, 'Widths', [-1, -1]);
		end
		
		function [h, p] = verticalBoxWithBoldLabel(parentHandle, str, varargin)
			% VERTICALBOXWITHBOLDLABEL
			p = uix.VBox('Parent', parentHandle,...
				'BackgroundColor', 'w');
			h = uicontrol(p, 'Style', 'text', 'String', str, 'FontWeight', 'bold');
			uicontrol(p, varargin{:});
			set(p, 'Heights', [-0.75, 1]);
		end

		function [h, p] = horizontalBoxWithBoldLabel(parentHandle, str, varargin)
			% HORIZONTALBOXWITHBOLDLABEL
            p = uix.HBox('Parent', parentHandle,...
                'BackgroundColor', 'w');
            h = uicontrol(p, 'Style', 'text', 'String', str, 'FontWeight', 'bold');
            uicontrol(p, varargin{:});
            set(p, 'Widths', [-1, -1]);
		end
	end
end
