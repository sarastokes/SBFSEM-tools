classdef Interface < handle
% SBFSEM.UI.INTERFACE
%
% Description:
%   Generic two-panel user interface (controls left, plot right)
%
% History:
%   8May2018 - SSP - created as generic version of TogglePartsView
% ----------------------------------------------------------------------

    properties (Access = protected, Hidden = true)
        ui = struct();
        figureHandle
        ax
        azel = [-37.5, 30];
    end

    methods
        function obj = Interface()
            obj.figureHandle = figure(...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolBackgroundColor', 'w',...
                'KeyPressFcn', @obj.onKeyPress);
            mainLayout = uix.HBoxFlex(...
                'Parent', obj.figureHandle,...
                'BackgroundColor', 'w');
            obj.ui.root = uix.VBox(...
                'Parent', mainLayout,...
                'BackgroundColor', 'w');
            obj.ui.plot = uipanel(mainLayout,...
                'BackgroundColor', 'w');
            obj.ax = axes('Parent', obj.ui.plot);
            obj.ui.ctrl = uix.VBoxFlex(...
                'Parent', obj.ui.root,...
                'BackgroundColor', 'w');
        end
        
        function S = debug(obj)
            % DEBUG  Return a structure of handles
            
            S = struct();
            S.ui = struct(obj.ui);
            S.figureHandle = struct(obj.figureHandle);
            S.ax = struct(obj.ax);
        end
    end

    methods (Access = protected)
        function onKeyPress(obj, ~, evt)
            % ONKEYPRESS
            %   Keyboard control over plot rotation
            switch evt.Character
                case {'h', 'a'}
                    obj.azel(1) = obj.azel(1) - 5;
                case {'j', 's'}
                    obj.azel(2) = obj.azel(2) - 5;
                case {'k', 'w'}
                    obj.azel(2) = obj.azel(2) + 5;
                case {'l', 'd'}
                    obj.azel(1) = obj.azel(1) + 5;
                otherwise
                    return;
            end
            if abs(obj.azel(1)) < 5 
                obj.azel(1) = 0;
            end
            if abs(obj.azel(2)) < 5
                obj.azel(2) = 0;
            end
            view(obj.ax, obj.azel);
        end
    end

    methods (Static, Access = protected)
       function hexColor = rgb2hex(rgbColor)
            % RGB2HEX  Streamlined version of rgb2hex
            % https://www.mathworks.com/matlabcentral/fileexchange/46289-rgb2hex-and-hex2rgb
            if max(rgbColor(:)) <= 1
                rgbColor = round(rgbColor * 255);
            else
                rgbColor = round(rgbColor);
            end
            hexColor(:,2:7) = reshape(sprintf('%02X', rgbColor.'), 6,[]).';
            hexColor(:,1) = '#';
        end
    end
end
