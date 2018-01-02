classdef (Abstract) TogglePartsView < handle
    
    properties (GetAccess = public, SetAccess = protected)
        parts = containers.Map();
        partNames
        ui = struct();
        tableData
        legendColors
        figureHandle
        ax
        columnNames
    end

    properties (Constant = true, Access = protected)
        NAMECOL = 3;
    end
    
    methods
        function obj = TogglePartsView()
            obj.figureHandle = figure(...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolBackgroundColor', 'w');
            mainLayout = uix.HBoxFlex(...
                'Parent', obj.figureHandle,...
            	'BackgroundColor', 'w');
            obj.ui.root = uix.VBox('Parent', mainLayout,...
            	'BackgroundColor', 'w');
            obj.ui.plot = uix.Panel('Parent', mainLayout,...
            	'BackgroundColor', 'w');
            obj.ax = axes('Parent', obj.ui.plot);
            obj.ui.ctrl = uix.VBoxFlex('Parent', obj.ui.root,...
            	'BackgroundColor', 'w');
            obj.ui.dataTable = uitable('Parent', obj.ui.root);

            obj.setDefaults();
        end       
    end
    
    methods (Access = protected)
        function assembleTable(obj)
            % Make the basic table
            if isempty(obj.legendColors)
                obj.legendColors = pmkmp(numel(obj.partNames), 'CubicL');
            end
            obj.tableData = cell(numel(obj.partNames), 3);
            for i = 1:numel(obj.partNames)
                obj.tableData{i, 1} = true;
                co = obj.rgb2hex(obj.legendColors(i,:));
                obj.tableData{i, 2} = obj.setTableCellColor(co, ' ');
                obj.tableData{i, 3} = char(obj.partNames(i));
            end
            obj.columnNames = {'Show', '', 'Name'};
            set(obj.ui.dataTable,...
                'Data', obj.tableData,...
                'ColumnName', obj.columnNames,...
                'FontSize', 10,...
                'FontName', 'Segoe UI',...
                'ColumnEditable', [true false false]);
        end

        function togglePart(obj, whichPart, toggleState)
        	% TOGGLEPART  Adds/removes line from plot
        	toggleState = validatestring(toggleState, {'on', 'off'});
        	set(obj.parts(whichPart), 'Visible', toggleState);
        end

        function setDefaults(obj)
        	set(findall(obj.figureHandle, 'Type', {'uix.Panel', 'uix.Box'}),...
        		'BackgroundColor', 'w');
        end

        function colorBySynapse(obj)
        	obj.legendColors = cell2mat(arrayfun(@(x) x.StructureColor,...
                obj.partNames, 'UniformOutput', false));
        end
    end
    
    methods (Static)
        function x = setTableCellColor(hexColor, str)
            % SETTABLECELLCOLOR  Sets legend cell of data table
            x = ['<html><table border=0 width=200 bgcolor=',...
                hexColor, '><TR><TD>', str,...
                '</TD></TR> </table></html>'];
        end
        
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
            binCenters = bins(1:end-1) + (bins(2)-bins(1))/2;
        end

        function exportFigure(ax, neuronID)
            % EXPORTFIGURE  Open figure in new window
            newAxes = copyobj(ax, figure);
            set(newAxes,...
                'ActivePositionProperty', 'outerposition',...
                'Units', 'normalized',...
                'OuterPosition', [0 0 1 1],...
                'Position', [0.13, 0.11, 0.775, 0.815],...
                'XColor', 'w',...
                'YColor', 'w');
            axis(newAxes, 'tight');
            if nargin == 2
                title(newAxes, ['c', num2str(neuronID)]);
            end
            % Keep only visible components
            hiddenLines = findall(newAxes, 'Type', 'line', 'Visible', 'off');
            delete(hiddenLines);
        end
    end
end