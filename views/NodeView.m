classdef NodeView < sbfsem.ui.TogglePartsView
    
    properties (SetAccess = private, Hidden = false)
        neuron
        azel = [-37.5, 30];
    end
    
    methods
        function obj = NodeView(neuron)
            % Setup from superclass
            obj@sbfsem.ui.TogglePartsView();
            
            assert(isa(neuron, 'Neuron'), 'Input a neuron object');
            if ~neuron.includeSynapses
                neuron.getSynapses();
            end
            
            % Add context menu to axis
            c = uicontextmenu;
            obj.ax.UIContextMenu = c;
            uimenu(c, 'Label', 'Rotate On', 'Callback', @obj.onAxisMenu);
            uimenu(c, 'Label', 'Grid on', 'Callback', @obj.onAxisMenu);
            
            assert(isa(neuron, 'Neuron'), 'Input a neuron object');
            obj.neuron = neuron;
            obj.partNames = neuron.synapseNames;
            
            % Plot the cell body nodes
            xyz = obj.populateNodeData('body');
            obj.parts('body') = line(...
                'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData',xyz(:,3),...
                'Parent', obj.ax,...
                'Color', [0.2 0.2 0.2],...
                'Marker', '.', 'MarkerSize', 4,...
                'LineStyle', 'none');
            
            % Add the soma
            xyz = obj.populateNodeData('soma');
            obj.parts('soma') = line(...
                'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData',xyz(:,3),...
                'Parent', obj.ax,...
                'Color', [0.2 0.2 0.2],...
                'Marker', '.', 'MarkerSize', 20,...
                'LineStyle', 'none');
            
            for i = 1:numel(obj.partNames)
                xyz = obj.populateNodeData(obj.partNames(i));
                obj.parts(char(obj.partNames(i))) = line(...
                    'XData', xyz(:, 1),...
                    'YData', xyz(:, 2),...
                    'ZData', xyz(:, 3),...
                    'Parent', obj.ax,...
                    'Color', obj.partNames(i).StructureColor,...
                    'Marker', '.', 'MarkerSize', 7,...
                    'LineStyle', 'none');
            end
            
            obj.colorBySynapse();
            obj.assembleTable();
            set(obj.ui.dataTable, 'CellEditCallback', @obj.onCellEdit);
            obj.adjustUI();
        end
    end
    
    methods (Access = private)
        function adjustUI(obj)
            set(obj.figureHandle,...
                'DefaultUiControlFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'NumberTitle', 'off',...
                'Name', 'NodeView',...
                'KeyPressFcn', @obj.onKeyPress);
            axis(obj.ax, 'tight');
            axis(obj.ax, 'equal');
            view(obj.ax, obj.azel);
            grid(obj.ax, 'on');
            
            xlabel(obj.ax, 'x-axis');
            ylabel(obj.ax, 'y-axis');
            zlabel(obj.ax, 'z-axis');
            
            uicontrol(obj.ui.ctrl,...
                'Style', 'text',...
                'String', 'Toggle synapses on and off with checkboxes');            
            uicontrol(obj.ui.ctrl,...
                'Style', 'text',...
                'String', 'Rotate with wasd or hjki');
            
            uicontrol(obj.ui.ctrl,...
                'Style', 'checkbox',...
                'String', 'Toggle cell body',...
                'Value', 1,...
                'Callback', @obj.onToggleBody);
            uicontrol(obj.ui.ctrl,...
                'Style', 'checkbox',...
                'String', 'Change cell body size',...
                'Value', 0,...
                'Callback', @obj.onChangeSize);
        end
        
        function xyz = populateNodeData(obj, partName)
            switch partName
                case 'soma'
                    xyz = obj.neuron.getSomaXYZ();
                case 'body'
                    xyz = obj.neuron.getCellXYZ();
                otherwise
                    xyz = obj.neuron.getSynapseXYZ(partName);
            end
        end
        
        function onToggleBody(obj, src, ~)
            if src.Value
                obj.togglePart('body', 'on');
            else
                obj.togglePart('body', 'off');
            end
        end
        
        function onChangeSize(obj, src, ~)
            if src.Value
                set(obj.parts('body'), 'MarkerSize', 2);
            else
                set(obj.parts('body'), 'MarkerSize', 4);
            end
        end
        
        function onAxisMenu(obj, src, ~)
            disp(src.Label)
            switch src.Label
                case 'Grid'
                    if strfind(src.Label, 'off')
                        grid(obj.ax, 'off');
                        src.Label = 'Grid on';
                    else
                        grid(obj.ax, 'on');
                        src.Label = 'Grid off';
                    end
                case 'Rota'
                    if strfind(src.Label, 'off')
                        rotate3d(obj.ax, 'off');
                        src.Label = 'Rotate on';
                    else
                        rotate3d(obj.ax, 'on');
                        src.Label = 'Rotate off';
                    end
            end
        end
        
        function onCellEdit(obj, src, eventdata)
            tableData = src.Data;
            tableInd = eventdata.Indices;
            % Hard coded column number for synapse name
            whichPart = tableData{tableInd(1), obj.NAMECOL};
            tof = tableData(tableInd(1), tableInd(2));
            if tableInd(2) == 1
                if tof{1}
                    obj.togglePart(whichPart, 'on');
                else
                    obj.togglePart(whichPart, 'off');
                end
            end
        end
        
        function onKeyPress(obj, ~, eventdata)
            switch eventdata.Character
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
            view(obj.ax, obj.azel);
        end
    end
end