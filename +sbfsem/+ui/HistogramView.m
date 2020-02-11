classdef HistogramView < handle
% HISTOGRAMVIEW
%
% Description:
%   Histogram with modifiable bin count
%
% Constructor:
%   obj = HistogramView(data, numBins)
%
% Properties:
%   figureHandle        Handle to figure
%   plotHandle          Handle to histogram plot object
%   axHandle            Handle to axis
%
% History:
%   2Feb2020 - SSP
% ------------------------------------------------------------------------

    properties
        figureHandle
        plotHandle
        axHandle
    end

    properties (Access = private)
        data
        numBins
    end

    methods 
        function obj = HistogramView(data, numBins)
            obj.data = data;
            if nargin == 2
                obj.numBins = numBins;
            end
            obj.createUi();
            obj.setHistogram();
            set(findobj(obj.figureHandle, 'Tag', 'BinDisplay'),...
                'String', num2str(obj.numBins));
            set(findobj(obj.figureHandle, 'Tag', 'XMin'),...
                'String', num2str(obj.axHandle.XLim(1)));
            set(findobj(obj.figureHandle, 'Tag', 'XMax'),...
                'String', num2str(obj.axHandle.XLim(2)));
        end

    end

    methods (Access = private)

        function setHistogram(obj)
            % SETHISTOGRAM  
            if isempty(obj.numBins)
                [counts, binCenters] = obj.getHist(obj.data);
                obj.numBins = numel(counts);
            else
                [counts, binCenters] = obj.getHist(obj.data, obj.numBins);
            end
            set(obj.plotHandle, 'XData', binCenters, 'YData', counts);
        end

        function onBinDown(obj, ~, ~)
            % ONBINDOWN  Decrease bin count by 1
            if obj.numBins == 1
                return;
            end
            obj.numBins = obj.numBins - 1;
            obj.updateView();
        end

        function onBinUp(obj, ~, ~)
            % ONBINUP  Increase bin count by 1
            obj.numBins = obj.numBins + 1;
            obj.updateView();
        end
        
        function onBinDown10(obj, ~, ~)
            % ONBINDOWN10  Decrease bin count by 10
            if obj.numBins <= 10
                return;
            end
            obj.numBins = obj.numBins - 10;
            obj.updateView();
        end

        function onBinUp10(obj, ~, ~)
            % ONBINUP10  Increase bin count by 10
            obj.numBins = obj.numBins + 10;
            obj.updateView();
        end

        function onSetMinX(obj, src, ~)
            % ONSETMINX
            try
                xMin = str2double(src.String);
                set(src, 'ForegroundColor', 'k');
            catch
                set(src, 'ForegroundColor', 'r');
            end
            obj.axHandle.XLim(1) = xMin;
        end

        function onSetMaxX(obj, src, ~)
            % ONSETMAXX
            try
                xMax = str2double(src.String);
                set(src, 'ForegroundColor', 'k');
            catch
                set(src, 'ForegroundColor', 'r');
            end
            obj.axHandle.XLim(2) = xMax;
        end

        function updateView(obj)
            set(findobj(obj.figureHandle, 'Tag', 'BinDisplay'), ...
                'String', num2str(obj.numBins));
            obj.setHistogram();
        end

        function onKeyPress(obj, ~, evt)
            % ONKEYPRESS  Control bin count with arrow keys

            switch evt.Key
                case 'leftarrow'
                    if ~isempty(evt.Modifier) && strcmp(evt.Modifier{1}, 'shift')
                        obj.onBinDown10();
                    else
                        obj.onBinDown();
                    end
                case 'rightarrow'
                    if ~isempty(evt.Modifier) && strcmp(evt.Modifier{1}, 'shift')
                        obj.onBinUp10();
                    else
                        obj.onBinUp();
                    end
            end
        end

        function createUi(obj)
            obj.figureHandle = figure(...
                'Name', 'Histogram View',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 11,...
                'Color', 'w',...
                'KeyPressFcn', @obj.onKeyPress);

            LayoutManager = sbfsem.ui.LayoutManager;

            mainLayout = uix.HBox('Parent', obj.figureHandle,...
                'BackgroundColor', 'w');

            uiLayout = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', 'w');
            uicontrol(uiLayout,...
                'Style', 'text', 'String', 'Bins');
            binLayout = uix.HBox('Parent', uiLayout,...
                'BackgroundColor', 'w');
            uicontrol(binLayout,...
                'Style', 'push', 'String', '<--',...
                'Callback', @obj.onBinDown);
            uicontrol(binLayout,...
                'Style', 'text', 'String', '',...
                'Tag', 'BinDisplay');
            uicontrol(binLayout,...
                'Style', 'push', 'String', '-->',...
                'Callback', @obj.onBinUp);

            uix.Empty('Parent', uiLayout,...
                'BackgroundColor', 'w');
            
            uicontrol(uiLayout,...
                'Style', 'text', 'String', 'Axis Limits',...
                'FontWeight', 'bold');
            axisLayout = uix.HBox('Parent', uiLayout,...
                'BackgroundColor', 'w');
            uicontrol(axisLayout,...
                'Style', 'text', 'String', 'X');
            uicontrol(axisLayout,...
                'Style', 'edit',...
                'String', '0',...
                'Tag', 'XMin',... 
                'Callback', @obj.onSetMinX);
            uicontrol(axisLayout,...
                'Style', 'edit', 'Tag', 'XMax',...
                'Callback', @obj.onSetMaxX);
            uicontrol(axisLayout,...
                'Style', 'text', 'String', 'Y');

            uix.Empty('Parent', uiLayout,...
                'BackgroundColor', 'w');
            
            LayoutManager.verticalBoxWithBoldLabel(uiLayout, 'Mean:',...
                'Style', 'text',... 
                'String', num2str(round(mean(obj.data), 3)),...
                'Tag', 'MeanDisplay');
            LayoutManager.verticalBoxWithBoldLabel(uiLayout, 'SD:',...
                'Style', 'text',...
                'String', num2str(round(std(obj.data), 3)),...
                'Tag', 'SDDisplay');
            LayoutManager.verticalBoxWithBoldLabel(uiLayout, 'SEM:',...
                'Style', 'text',... 
                'String', num2str(round(sbfsem.util.sem(obj.data), 3)),...
                'Tag', 'SEMDisplay');
            LayoutManager.verticalBoxWithBoldLabel(uiLayout, 'Median:',...
                'Style', 'text',...
                'String', num2str(median(round(100 * obj.data))/100),...
                'Tag', 'VarDisplay');
            LayoutManager.verticalBoxWithBoldLabel(uiLayout, 'N:',...
                'Style', 'text',... 
                'String', num2str(numel(obj.data)),...
                'Tag', 'NDisplay');
            set(uiLayout, 'Heights', [30, 50, -1, 20, 20, -1, 50, 50, 50, 50, 50]);
            
            p = uipanel('Parent', mainLayout,...
                'BackgroundColor', 'w');
            obj.axHandle = axes('Parent', p);
            hold(obj.axHandle, 'on');
            grid(obj.axHandle, 'on');
            obj.plotHandle = plot(obj.axHandle, [0 1], [0 0],...
                'Color', 'k', 'Marker', 'o', 'LineWidth', 1);

            set(mainLayout, 'Widths', [-1, -4]);
        end
    end

    methods (Static)
        function [counts, binCenters] = getHist(x, numBins)
            % GETHIST  Get bin centers from histcounts
            if nargin < 2
                numBins = [];
            end

            if isempty(numBins)
                [counts, bins] = histcounts(x);
            else
                [counts, bins] = histcounts(x, numBins);
            end
            binCenters = bins(1:end-1) + (bins(2) - bins(1))/2;
        end
    end
end