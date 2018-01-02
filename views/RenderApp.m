classdef RenderApp < handle
    % RENDERAPP
    %
    % Description:
    %   UI for viewing renders and creating scenes to export to Blender
    % 
    % Constructor:
    %   obj = RenderApp(source);
    % 
    % WORK IN PROGRESS
    % ---------------------------------------------------------------------
    
    properties
        renders
        IDs
        source
        ui
    end
    
    properties (Access = private)
        figureHandle
        lights
        ax
    end
    
    properties (SetAccess = private, Transient = true)
        azel = [-37.5, 30];
        shiftXY = false;
    end
    
    properties (Constant = true, Hidden = true)
        SOURCES = {	'NeitzTemporalMonkey',...
            'NeitzInferiorMonkey',...
            'MarcRC1'};
        COLORS = [0,0.8,0.3; 0.8,0.3,0; 0.3,0,0.8];
    end
    
    methods
        function obj = RenderApp(source, shiftXY)
            if nargin > 0
                obj.source = validateSource(source);
            else
                [selection, selectedSource] = listdlg(...
                    'PromptString', 'Select a source:',...
                    'Name', 'RenderApp Source Selection',...
                    'SelectionMode', 'single',...
                    'ListString', obj.SOURCES);
                if selectedSource
                    obj.source = obj.SOURCES(selection);
                else
                    warning('No source selected... exiting');
                    return;
                end
            end
            
            if nargin == 2
                obj.shiftXY = shiftXY;
            end
            
            obj.renders = containers.Map();
            obj.createUI();
        end
        
        function setShiftXY(obj, shiftXY)
            assert(islogical(shiftXY), 'ShiftXY is t/f');
            obj.shiftXY = shiftXY;
        end
    end
    
    
    % Callback methods
    methods (Access = private)
        
        function onAddNeuron(obj, ~, ~)
            % TODO: input validation
            str = deblank(obj.ui.newID.String);
            if nnz(isletter(deblank(obj.ui.newID.String))) > 0
                warning('Neuron IDs = integers separated by commas');
                return;
            end
            str = strsplit(str, ',');
            for i = 1:numel(str)
                newID = str2double(str{i});
                
                obj.addNeuron(newID);
                
                newColor = findall(obj.ax, 'Tag', obj.id2tag(newID));
                newColor = get(newColor(1), 'FaceColor');
                
                if numel(obj.IDs) == 1
                    obj.ui.idList.Data(1,:) = {true, newID,... 
                        obj.setLegendCell(newColor)};
                else
                    obj.ui.idList.Data(end+1,:) = {true, newID,...
                        obj.setLegendCell(newColor)};
                end
                drawnow;
            end
            set(obj.ui.newID, 'String', '');
        end
        
        function onRmNeuron(~, ~, ~)
            disp('Not ready');
        end
        
        function onKeyPress(obj, ~, eventdata)
            % ONKEYPRESS  Control plot view with keyboard
            switch eventdata.Character
                case {'h', 'a'}
                    obj.azel(1) = obj.azel(1) - 5;
                case {'j', 's'}
                    % elevation down
                    obj.azel(2) = obj.azel(2) - 5;
                case {'k', 'w'}
                    % elevation up
                    obj.azel(2) = obj.azel(2) + 5;
                case {'l', 'd'}
                    % right
                    obj.azel(2) = obj.azel(1) + 5;
                case {'J', 'S'}
                    % zoom out
                case {'K', 'W'}
                    % zoom in
                otherwise
                    return;
            end
            view(obj.ax, obj.azel);
        end
        
        function onCellSelect(obj, src, eventdata)
            % ONCELLSELECT  Table cell selection callback
            ind = eventdata.Indices;
            if isempty(ind)
                return;
            elseif ind(2) == 3
                newColor = uisetcolor();
                src.Data{ind(1), ind(2)} = obj.setLegendCell(newColor);
                neuronTag = obj.id2tag(src.Data{ind(1), 2});
                set(findall(obj.ax, 'Tag', neuronTag), 'FaceColor', newColor);
            end
        end
    end
    
    methods (Access = private)
        function addNeuron(obj, newID)
            disp(['Importing new neuron ', num2str(newID)]);
            neuron = sbfsem.Neuron(newID, obj.source, 'xyShift', obj.shiftXY);
            neuron3d = sbfsem.render.Cylinder(neuron);
            neuron3d.render('ax', obj.ax);
            obj.renders(num2str(newID)) = neuron3d;
            obj.IDs = cat(2, obj.IDs, newID);
        end
        
        function createUI(obj)
            obj.figureHandle = figure(...
                'Name', 'RenderApp',...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'KeyPressFcn', @obj.onKeyPress);
            
            mainLayout = uix.HBoxFlex('Parent', obj.figureHandle,...
                'BackgroundColor', 'w');
            
            % Create the user interface panel
            obj.ui.root = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 10, 'Padding', 5);
            obj.ui.source = uicontrol('Parent', obj.ui.root,...
                'Style', 'text',...
                'String', obj.source);
            
            obj.ui.idList = uitable('Parent', obj.ui.root,...
                'Data', {false, 0, obj.setLegendCell([1 1 1])});
            set(obj.ui.idList,...
                'ColumnName', {'', 'ID', ''},...
                'ColumnWidth', {20, 'auto', 20},...
                'ColumnEditable', [true, false, false],...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'),...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'),...
                'CellSelectionCallback', @obj.onCellSelect);
            
            idLayout = uix.HBox('Parent', obj.ui.root,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5);
            uicontrol('Parent', idLayout,...
                'Style', 'text',...
                'String', 'Neuron ID:');
            obj.ui.newID = uicontrol('Parent', idLayout,...
                'Style', 'edit',...
                'String', '');
            
            % Add/remove neurons
            pmLayout = uix.HBox('Parent', obj.ui.root,...
                'BackgroundColor', 'w',...
                'Spacing', 5);
            obj.ui.add = uicontrol('Parent', pmLayout,...
                'Style', 'push',...
                'String', '+',...
                'Callback', @obj.onAddNeuron);
            obj.ui.rm = uicontrol('Parent', pmLayout,...
                'Style', 'push',...
                'String', '-',...
                'Callback', @obj.onRmNeuron);
            set(obj.ui.root, 'Heights', [-0.5 -4 -1 -1]);
            
            % Create the render axis
            obj.ax = axes('Parent', mainLayout);
            axis(obj.ax, 'equal');
            axis(obj.ax, 'tight');
            grid(obj.ax, 'on');
            view(obj.ax, 3);
            
            % Set up the lighting
            obj.lights = [light(obj.ax), light(obj.ax)];
            lightangle(obj.lights(1), 45, 30);
            lightangle(obj.lights(2), 225, 30);
            
            set(mainLayout, 'Widths', [-1 -3]);
        end
    end
    
    methods (Static = true)
        function x = setLegendCell(rgbColor, str)
            % SETLEGENDCELL  Converts cell in table to legend bar
            if nargin < 2
                str = ' ';
            end
            rgbColor = round(rgbColor * 255);
            hexColor = reshape(sprintf('%02X', rgbColor.'), 6, []).';
            hexColor = ['#', hexColor];
            x = ['<html><table border=0 width=200 bgcolor=',...
                hexColor, '><TR><TD>', str,...
                '</TD></TR> </table></html>'];
        end
        
        function tag = id2tag(id)
            % ID2TAG  Quick fcn for (127 -> 'c127')
            tag = sprintf('c%u', id);
        end
    end
end