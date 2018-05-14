classdef View < handle
% SBFSEM.UI.VIEW
%
% Description:
%   Generic single panel interface.
%
% Protected properties:
%   figureHandle        handle to figure window
%   ui                  structure to hold ui handles
%
% History:
%   8May2018 - SSP - simplified version of Interface
% ----------------------------------------------------------------------

    properties (Access = protected)
        figureHandle
        ui = struct();
    end

    methods
        function obj = View()
            obj.figureHandle = figure(...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolBackgroundColor', 'w');
            obj.ui.root = uipanel(...
                'Parent', obj.figureHandle,...
                'BackgroundColor', 'w');
        end
    end
end
