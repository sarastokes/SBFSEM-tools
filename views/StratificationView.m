classdef StratificationView < sbfsem.ui.TogglePartsView
    
    properties (SetAccess = private)
        neuron
        bins = containers.Map();
    end
    
    methods
        function obj = StratificationView(neuron)
            obj@sbfsem.ui.TogglePartsView();
            assert(isa(neuron, 'Neuron'), 'Input a neuron object');
            if ~neuron.includeSynapses
                neuron.getSynapses();
            end
            
            obj.neuron = neuron;
            obj.partNames = neuron.synapseNames;
            
            obj.parts('body') = obj.getHistogramPart('body');
            
            obj.colorBySynapse();
            obj.assembleTable();
            
            for i = 1:numel(obj.partNames)
                [obj.parts(char(obj.partNames(i))), obj.bins(char(obj.partNames(i)))] = ...
                    obj.getHistogramPart(obj.partNames(i));
            end
            
            obj.setBinColumns();
            
            set(obj.ui.dataTable,...
                'CellEditCallback', @obj.onCellEdit);
            
            obj.adjustUI();
        end
    end
    
    methods (Access = private)
        function adjustUI(obj)
            set(obj.figureHandle,...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'NumberTitle', 'off',...
                'Name', 'Stratification View');
            % Normalize cell annotations
            xmax = sort(arrayfun(@(x) max(x.XData), obj.ax.Children), 'descend');
            xmax = xmax(2);
            xdata = get(obj.parts('body'), 'XData');
            set(obj.parts('body'), 'XData', xmax*(xdata/max(abs(xdata))));
            
            xlabel(obj.ax, 'Number of synapses');
            ylabel(obj.ax, 'Z-axis');
            set(obj.ax, 'YDir', 'reverse');
            obj.ax.XLim(1) = 1;
            
            % Instructions

            uicontrol(obj.ui.ctrl,...
                'Style', 'text',...
                'String', 'Edit table to change bin numbers');
            uicontrol(obj.ui.ctrl,...
                'Style', 'text',...
                'String', 'Toggle synapses on and off with checkboxes');
            uicontrol(obj.ui.ctrl,...
                'Style', 'text',...
                'String', 'Note: dendrites stratification is normalized to the max synapse count');
            % Add cell body toggle
            uicontrol(obj.ui.ctrl,...
                'Style', 'checkbox',...
                'String', 'Show dendrites',...
                'Value', 1,...
                'Callback', @obj.onShowDendrites);
        end
               
        function [plotObj, numBins] = getHistogramPart(obj, partName, numBins)
            if nargin < 3
                numBins = [];
            end
            
            switch partName
                case 'body'
                    xyz = obj.neuron.getCellXYZ;
                otherwise
                    xyz = obj.neuron.getSynapseXYZ(partName);
            end
            [counts, binCenters] = obj.getHist(xyz(:,3), numBins);
            
            numBins = numel(counts);
            
            plotObj = line('Parent', obj.ax,...
                'XData', counts, 'YData', binCenters,...
                'Marker', 'o',...
                'LineWidth', 1);
            
            switch partName
                case 'body'
                    set(plotObj, 'Color', 'k');
                otherwise
                    set(plotObj, 'Color', partName.StructureColor);
            end
        end
        
        function onShowDendrites(obj, src, ~)
            switch src.Value
                case 0
                    obj.togglePart('body', 'off');
                case 1
                    obj.togglePart('body', 'on');
            end
        end
        
        function onCellEdit(obj, src, eventdata)
            tableData = src.Data;
            tableInd = eventdata.Indices;
            whichPart = tableData{tableInd(1), obj.NAMECOL};
            tof = tableData(tableInd(1), tableInd(2));
            switch tableInd(2)
                case 1 % show
                    if tof{1}
                        obj.togglePart(whichPart, 'on');
                    else
                        obj.togglePart(whichPart, 'off');
                    end
                case 5 % bins
                    numBins = tableData{tableInd(1), tableInd(2)};
                    switch whichPart
                        case 'body'
                            xyz = obj.neuron.getCellXYZ;
                        otherwise
                            xyz = obj.neuron.getSynapseXYZ(...
                                sbfsem.core.StructureTypes(whichPart));
                    end
                    [counts, binCenters] = obj.getHist(xyz(:,3), numBins);
                    set(obj.parts(whichPart),...
                        'XData', counts,...
                        'YData', binCenters);
                    obj.bins(whichPart) = numBins;
            end
        end
        
        function setBinColumns(obj)
            data = obj.ui.dataTable.Data;
            columnEditable = obj.ui.dataTable.ColumnEditable;
            columnNames = cat(2, obj.columnNames, {'N', 'bins'});
            
            newCols = cell(size(data, 1), 2);
            for i = 1:size(data, 1)
                newCols{i,1} = sum(get(obj.parts(data{i,obj.NAMECOL}), 'XData'));
                newCols{i,2} = obj.bins(data{i,obj.NAMECOL});
            end
            set(obj.ui.dataTable,...
                'Data', [data, newCols],...
                'ColumnName', columnNames,...
                'ColumnEditable', [columnEditable, false, true],...
                'ColumnWidth', {35, 20, 100, 30, 30});
            
            obj.columnNames = columnNames;
        end
    end
end