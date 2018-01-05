classdef SomaDistanceView < sbfsem.ui.TogglePartsView
    
    properties (SetAccess = private)
        neuron
        bins = containers.Map();
    end
    
    properties (SetAccess = private, Hidden = true)
        somaLocation
    end
    
    methods
        function obj = SomaDistanceView(neuron)
            obj@sbfsem.ui.TogglePartsView();
            assert(isa(neuron, 'Neuron'), 'Input a neuron object');
            
            if ~neuron.includeSynapses
                neuron.getSynapses();
            end
            
            obj.neuron = neuron;
            obj.somaLocation = neuron.getSomaXYZ();
            obj.somaLocation = obj.somaLocation(1,:);
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
                'Name', 'Soma Distance View');
            
    		% Normalize cell annotations
    		ymax = sort(arrayfun(@(x) max(x.YData), obj.ax.Children), 'descend');
    		ymax = ymax(2);
    		ydata = get(obj.parts('body'), 'YData');
    		set(obj.parts('body'), 'YData', ymax*(ydata/max(abs(ydata))));

            xlabel(obj.ax, 'Distance from soma (microns)');
            ylabel(obj.ax, 'Number of synapses');
            
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
            somaDistance = fastEuclid3d(obj.somaLocation, xyz);
            
            [counts, binCenters] = obj.getHist(somaDistance, numBins);
            
            numBins = numel(counts);
            
            plotObj = line('Parent', obj.ax,...
                'XData', binCenters, 'YData', counts,...
                'Marker', 'o',...
                'LineWidth', 1);
            
            switch partName
                case 'body'
                    set(plotObj, 'Color', 'k');
                otherwise
                    set(plotObj, 'Color', partName.StructureColor);
            end
        end
       
        function onCellEdit(obj, src, eventdata)
            tableData = src.Data;
            tableInd = eventdata.Indices;
        	% Hard coded column number for synapse name
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
            		somaDistance = fastEuclid3d(obj.somaLocation, xyz);
                	[counts, binCenters] = obj.getHist(somaDistance, numBins);
                	set(obj.parts(whichPart),...
                		'XData', binCenters,...
                		'YData', counts);
                	obj.bins(whichPart) = numBins;
            end
        end

        function setBinColumns(obj)
        	data = obj.ui.dataTable.Data;
        	columnEditable = obj.ui.dataTable.ColumnEditable;
        	columnNames = cat(2, obj.columnNames, {'N', 'bins'});

        	newCols = cell(size(data, 1), 2);
        	for i = 1:size(data, 1)
        		newCols{i,1} = sum(get(obj.parts(data{i,obj.NAMECOL}), 'YData'));
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