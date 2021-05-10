classdef PolarHistogramView < handle 
% POLARHISTOGRAMVIEW
%
% Constructor:
%   obj = PolarHistogramView(data, varargin)
%
% Inputs:
%   data        vector
%       Values in radians
% Additional key/value inputs are passed to polarhistogram
%
% See also:
%   POLARHISTOGRAM
%
% History:
%   3Jan2020 - SSP
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        data 
        histHandle
    end
    
    properties (Hidden, Access = private)
        axHandle 
        figureHandle
    end

    methods 
        function obj = PolarHistogramView(data, varargin)
            obj.data = data;

            obj.createUi(varargin{:});
        end
    end

    methods (Access = private)
        function onKeyPress(obj, ~, evt)
            
            switch evt.Key
                case 'leftarrow'
                    obj.histHandle.fewerbins();
                case 'rightarrow'
                    obj.histHandle.morebins();
                otherwise
                    return
            end

            set(findobj(obj.figureHandle, 'Tag', 'binText'),...
                'String', ['Bins = ', num2str(obj.histHandle.NumBins)]);
        end

        function onChanged_Normalization(obj, src, ~)
            normType = src.String{src.Value};
            obj.histHandle.Normalization = normType;

            if strcmp(normType, 'probability')
                obj.axHandle.RLim = [0 1];
            else
                obj.axHandle.RLimMode = 'auto';
            end
        end
    end

    methods (Access = private)
        function createUi(obj, varargin)
            obj.figureHandle = figure(...
                'Name', 'Polar Hist View',...
                'DefaultUicontrolFontSize', 12,...
                'DefaultUicontrolBackground', 'w',...
                'KeyPressFcn', @obj.onKeyPress);

            mainLayout = uix.VBoxFlex('Parent', obj.figureHandle,...
                'BackgroundColor', 'w');
            uiLayout = uix.HBox('Parent', mainLayout,...
                'BackgroundColor', 'w');
            p = uipanel('Parent', mainLayout,...
                'BackgroundColor', 'w');
            set(mainLayout, 'Heights', [-1, -10]);

            obj.axHandle = polaraxes('Parent', p);
            obj.histHandle = polarhistogram(...
                obj.axHandle, obj.data, varargin{:});
            
            uicontrol(uiLayout, 'Style', 'text',...
                'String', ['Bins = ', num2str(obj.histHandle.NumBins)],... 
                'Tag', 'binText');
            uicontrol(uiLayout, 'Style', 'text', 'String', 'Normalization:');
            uicontrol(uiLayout, 'Style', 'popup',...
                'String', {'count', 'probability'},...
                'Callback', @obj.onChanged_Normalization);

        end
    end
end 