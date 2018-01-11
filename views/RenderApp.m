classdef RenderApp < handle
    % RENDERAPP
    %
    % Description:
    %   UI for viewing renders and creating scenes to export to Blender
    %
    % Constructor:
    %   obj = RenderApp(source);
    %
    % Example:
    %   RenderApp('i');
    %
    % Todo:
    %   - Remove a neuron entirely
    %   - Check for duplicate neurons
    %   - Synapses
    %
    % History:
    %   5Jan2017 - SSP
    % ---------------------------------------------------------------------
    
    properties (Access = private)
        neurons             % Neuron objects
        IDs                 % IDs of neuron objects
        source              % Volume name
        volumeScale         % Volume dimensions (nm/pix)
        
        figureHandle        % Parent figure handle
        ui                  % UI panel handles
        ax                  % Render axis
        lights              % Light handles
        isInverted          % Is axis color inverted
        
        % UI controls
        azel = [-37.5, 30];
        zoomFac = 0.9;
        panFac = 0.02;
        shiftXY = false;
    end
    
    properties (Constant = true, Hidden = true)
        SYNAPSES = false;
        SOURCES = {	'NeitzTemporalMonkey',...
            'NeitzInferiorMonkey',...
            'MarcRC1'};
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
                    obj.source = obj.SOURCES{selection};
                    fprintf('Running with %s\n', obj.source);
                else
                    warning('No source selected... exiting');
                    return;
                end
            end
            
            if nargin == 2
                obj.shiftXY = shiftXY;
            end
            
            obj.neurons = containers.Map();
            obj.createUI();
            
            obj.volumeScale = getODataScale(obj.source);
            obj.isInverted = false;
        end
        
        function setShiftXY(obj, shiftXY)
            assert(islogical(shiftXY), 'ShiftXY is t/f');
            obj.shiftXY = shiftXY;
        end
    end
    
    % Callback methods
    methods (Access = private)
        function onAddNeuron(obj, src, ~)
            % TODO: better input validation
            
            % No input detected
            if isempty(obj.ui.newID.String)
                return;
            end
            
            % Separate neurons by commas
            str = deblank(obj.ui.newID.String);
            if nnz(isletter(deblank(obj.ui.newID.String))) > 0
                warning('Neuron IDs = integers separated by commas');
                return;
            end
            str = strsplit(str, ',');
            
            % Clear out accepted input string so user doesn't accidentally
            % add the neuron twice while program runs.
            set(obj.ui.newID, 'String', '');
            
            % Import the new neuron(s)
            for i = 1:numel(str)
                newID = str2double(str{i});
                
                obj.addNeuron(newID);
                
                newColor = findall(obj.ax, 'Tag', obj.id2tag(newID));
                newColor = get(newColor(1), 'FaceColor');
                
                if numel(obj.IDs) == 1
                    obj.ui.idList.Data(1,:) = {true, newID,...
                        obj.setLegendCell(newColor)};
                    set(obj.ui.plot.Children, 'Enable', 'on');
                else
                    obj.ui.idList.Data(end+1,:) = {true, newID,...
                        obj.setLegendCell(newColor)};
                end
                % Update the plot after each neuron imports
                drawnow;
            end
            set(src, 'Enable', 'on',...
                'String', '+');
        end
        
        function onKeyPress(obj, ~, eventdata)
            % ONKEYPRESS  Control plot view with keyboard
            %
            % See also: AXDRAG
            switch eventdata.Character
                case 'h' % help
                    helpdlg(obj.getInstructions, 'RenderApp Instructions');
                case 28 % azimuth down
                    obj.azel(1) = obj.azel(1) - 5;
                case 30 % elevation down
                    obj.azel(2) = obj.azel(2) - 5;
                case 31 % elevation up
                    obj.azel(2) = obj.azel(2) + 5;
                case 29 % azimuth up
                    obj.azel(1) = obj.azel(1) + 5;
                case {'z', 'Z'} % zoom
                    if eventdata.Character == 'Z'
                        obj.zoomFac = 1/obj.zoomFac;
                    end
                    
                    x = get(obj.ax, 'XLim');
                    y = get(obj.ax, 'YLim');
                    
                    set(obj.ax, 'XLim',...
                        [0, obj.zoomFac*diff(x)] + x(1)...
                        + (1-obj.zoomFac) * diff(x)/2);
                    set(obj.ax, 'YLim', [0, obj.zoomFac*diff(y)] + y(1)...
                        + (1-obj.zoomFac) * diff(y)/2);
                case 'a'
                    x = get(obj.ax, 'XLim');
                    set(obj.ax, 'XLim', x + obj.panFac * diff(x));
                case 'd'
                    x = get(obj.ax, 'XLim');
                    set(obj.ax, 'XLim', x - obj.panFac * diff(x));
                case 'e'
                    y = get(gca, 'YLim');
                    set(obj.ax, 'YLim', y + obj.panFac * diff(y));
                case 'q'
                    y = get(gca, 'YLim');
                    set(obj.ax, 'YLim', y - obj.panFac * diff(y));
                case 'w'
                    z = get(obj.ax, 'ZLim');
                    set(obj.ax, 'ZLim', z + obj.panFac * diff(z));
                case 's'
                    z = get(obj.ax, 'ZLim');
                    set(obj.ax, 'ZLim', z - obj.panFac * diff(z));
                case 'm' % Return to original dimensions
                    axis(obj.ax, 'tight');
                case 'c' % Copy the last click
                    % Don't copy position if no neurons are plotted
                    if isempty(obj.neurons)
                        return;
                    end
                    % Convert microns to Viking pixel coordinates
                    posMicrons = mean(get(obj.ax, 'CurrentPoint')); %um
                    um2pix = obj.volumeScale/1e3; % nm/pix -> um/pix
                    posViking = posMicrons./um2pix; % pix
                    
                    locationStr = obj.formatCoordinates(posViking);
                    clipboard('copy', locationStr);
                    fprintf('Copied to clipboard:\n %s\n', locationStr);
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
            end
            
            if ind(2) == 3
                % Open UI to choose new color, reflect change in table
                newColor = selectcolor('hCaller', obj.figureHandle);
                if isempty(newColor)
                    return; % User cancelled out of dialog box
                end
                src.Data{ind(1), ind(2)} = obj.setLegendCell(newColor);
                
                % Use neuron's tag to change patch color
                neuronTag = obj.id2tag(src.Data{ind(1), 2});
                set(findall(obj.ax, 'Tag', neuronTag),...
                    'FaceColor', newColor);
            end
        end
        
        function onCellEdit(obj, src, eventdata)
            % ONCELLEDIT  Cell edit callback
            
            ind = eventdata.Indices;
            if ind(2) == 1
                tof = src.Data(ind(1), ind(2));
                neuronTag = obj.id2tag(src.Data{ind(1), 2});
                if tof{1}
                    obj.toggleRender(neuronTag, 'on');
                else
                    obj.toggleRender(neuronTag, 'off');
                end
            end
        end
        
        function onToggleGrid(obj, src, ~)
            % TOGGLEGRID  Show/hide the grid
            
            if src.Value == 1
                grid(obj.ax, 'on');
            else
                grid(obj.ax, 'off');
            end
        end
        
        function onToggleAxes(obj, src, ~)
            % ONTOGGLEAXES  Show/hide axes
            newColor = 'k';
            if src.Value == 1 && obj.isInverted
                newColor = 'w';
            elseif src.Value == 0 && ~obj.isInverted
                newColor = 'w';
            end
            set(obj.ax, 'XColor', newColor,...
                'YColor', newColor, 'ZColor', newColor);
        end
        
        function onToggleLights(obj, src, ~)
            % ONTOGGLELIGHTS  Turn lighting on/off
            if src.Value == 1
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'gouraud');
            else
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'none');
            end
        end
        
        function onToggleInvert(obj, src, ~)
            % ONINVERT  Invert figure colors
            if src.Value == 1
                bkgdColor = 'k';
                frgdColor = 'w';
                set(obj.ax, 'GridColor', [0.85, 0.85, 0.85]);
                obj.isInverted = true;
            else
                bkgdColor = 'w';
                frgdColor = 'k';
                set(obj.ax, 'GridColor', [0.15 0.15 0.15]);
                obj.isInverted = true;
            end
            set(obj.ax, 'Color', bkgdColor,...
                'XColor', frgdColor,...
                'YColor', frgdColor,...
                'ZColor', frgdColor);
            set(obj.ax.Parent,...
                'BackgroundColor', bkgdColor);
            
        end
        
        function setOpacity(obj, src, ~)
            % SETOPACITY
            set(findall(obj.ax, 'Type', 'patch'), 'FaceAlpha', src.Value);
        end
        
        function onExportImage(obj, ~, ~)
            % ONEXPORTIMAGE  Save renders as an image
            
            % Export figure to new window without uicontrols
            newAxes = obj.exportFigure();
            
            % Open a save dialog to get path, name and extension
            [fName, fPath] = uiputfile(...
                {'*.jpeg'; '*.png'; '*.tiff'},...
                'Save image as');
            
            % Catch when user cancels out of save dialog
            if isempty(fName) || isempty(fPath)
                return;
            end
            
            % Save by extension type
            switch fName(end-2:end)
                case 'png'
                    exten = '-dpng';
                case 'peg'
                    exten = '-djpeg';
                case 'iff'
                    exten = '-dtiff';
            end
            
            print(newAxes.Parent, [fPath, fName], exten, '-r600');
            fprintf('Saved as: %s\n', [fPath, fName]);
            delete(newAxes.Parent);
        end
        
        function onExportCollada(obj, ~, ~)
            % ONEXPORTCOLLADA  Export the scene as a .dae file
            
            % Prompt user for file name and path
            [fName, fPath] = uiputfile('*.dae', 'Save as');
            % Catch when user cancels out of save dialog
            if isempty(fName) || isempty(fPath)
                return;
            end
            exportSceneDAE(obj.ax, [fPath, fName]);
        end
        
        function onExportNeuron(obj, ~, ~)
            % ONEXPORTNEURON  Export Neuron objects to base workspace
            tags = obj.neurons.keys;
            for i = 1:numel(tags)
                assignin('base', sprintf('c%u', tags{i}),...
                    obj.neurons(tags{i}));
            end
        end
        
        function onExportFigure(obj, ~, ~)
            % ONEXPORTFIGURE  Copy figure to new window
            obj.exportFigure();
        end
    end
    
    methods (Access = private)
        function addNeuron(obj, newID)
            % ADDNEURON  Add a new neuron and render
            
            disp(['Importing new neuron ', num2str(newID)]);
            neuron = Neuron(newID, obj.source, obj.SYNAPSES, obj.shiftXY);
            % Build the 3D model
            neuron.build();
            % Render the neuron
            neuron.render('ax', obj.ax);
            obj.neurons(num2str(newID)) = neuron;
            obj.IDs = cat(2, obj.IDs, newID);
        end
        
        function removeNeuron(obj, ID)
            % REMOVENEURON
            % work in progress, not functional yet
            
            % Delete the row from the data table
            if size(obj.ui.idList.Data, 1) == 1
                set(obj.ui.idList.Data, obj.emptyTableData());
            else
                idRow = find(obj.ui.idList.Data == ID);
                obj.ui.idList.Data(idRow,:) = []; %#ok
            end
            
            % Clear out neuron data
            obj.neurons(ID) = [];
            obj.IDs(obj.IDs == ID) = [];
            
            % Delete the patch from the render
            delete(findall(obj.ax, 'Tag', obj.id2tag(ID)));
            
            disp(['Removed neuron ', num2str(ID)]);
            
        end
        
        function newAxes = exportFigure(obj)
            % EXPORTFIGURE  Open figure in a new window
            newAxes = exportFigure(obj.ax);
            axis(newAxes, 'tight');
            
            % Keep only the visible components
            patches = findall(newAxes, 'Type', 'patch', 'Visible', 'off');
            delete(patches);
            
            % % Match the plot modifiers
            set([newAxes, newAxes.Parent], 'Color', obj.ax.Color);
        end
        
        function toggleRender(obj, tag, toggleState)
            % TOGGLERENDER  Hide/show render
            
            % Get all renders with a specific tag
            set(findall(obj.ax, 'Tag', tag) , 'Visible', toggleState);
        end
        
        function createUI(obj)
            obj.figureHandle = figure(...
                'Name', 'RenderApp',...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'KeyPressFcn', @obj.onKeyPress);

            mh.import = uimenu('Parent', obj.figureHandle,...
                'Label', 'Import');
            uimenu('Parent', mh.import,...
                'Label', 'Cone Mosaic');
            uimenu('Parent', mh.import,...
                'Label', 'Neurons from workspace');
            uimenu('Parent', mh.import,...
                'Label', 'OData query');
            uimenu('Parent', mh.import,...
                'Label', 'Text file');
            mh.export = uimenu('Parent', obj.figureHandle,...
                'Label', 'Export');
            uimenu('Parent', mh.export,...
                'Label', 'Open in new figure window',...
                'Callback', @obj.onExportFigure);
            uimenu('Parent', mh.export,...
                'Label', 'Export as image',...
                'Callback', @obj.onExportImage);
            uimenu('Parent', mh.export,...
                'Label', 'Export as COLLADA',...
                'Callback', @obj.onExportCollada);
            uimenu('Parent', mh.export,...
                'Label', 'Send neurons to workspace',...
                'Callback', @obj.onExportNeuron);
            uimenu('Parent', obj.figureHandle,...
                'Label', 'Help')
            
            % Main layout with 2 panels (UI, axes)
            mainLayout = uix.HBoxFlex('Parent', obj.figureHandle,...
                'BackgroundColor', 'w');            
            % Create the user interface panel
            obj.ui.root = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5, 'Padding', 5);
            obj.ui.source = uicontrol(obj.ui.root,...
                'Style', 'text',...
                'String', obj.source);
            
            % Create the neuron table
            obj.ui.idList = uitable(obj.ui.root,...
                'Data', obj.emptyTableData);
            tableStr = ['Show or hide neurons with checkboxes',...
                'Click color cell to change'];
            set(obj.ui.idList,...
                'ColumnName', {'', 'ID', 'Color'},...
                'ColumnWidth', {25, 'auto', 30},...
                'ColumnEditable', [true, false, false],...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'),...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'),...
                'TooltipString', tableStr,...
                'CellSelectionCallback', @obj.onCellSelect,...
                'CellEditCallback', @obj.onCellEdit);
            
            % Add/remove neurons
            pmLayout = uix.HBox('Parent', obj.ui.root,...
                'BackgroundColor', 'w',...
                'Spacing', 5);
            idLayout = uix.VBox('Parent', pmLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5);
            uicontrol(idLayout,...
                'Style', 'text',...
                'String', 'IDs:');
            obj.ui.newID = uicontrol(idLayout,...
                'Style', 'edit',...
                'TooltipString', 'Input neuron IDs separated by commas',...
                'String', '');
            obj.ui.add = uicontrol(pmLayout,...
                'Style', 'push',...
                'String', '+',...
                'FontWeight', 'bold',...
                'FontSize', 20,...
                'TooltipString', 'Add neuron(s) in editbox',...
                'Callback', @obj.onAddNeuron);
            set(pmLayout, 'Widths', [-1.2, -0.8])
            
            % Plot modifiers
            uicontrol(obj.ui.root,...
                'Style', 'text',...
                'String', 'Plot modifiers:')
            obj.ui.plot = uix.Grid('Parent', obj.ui.root);
            uicontrol(obj.ui.plot,...
                'Style', 'check',...
                'String', 'Axes',...
                'TooltipString', 'Toggle axes',...
                'Value', 1,...
                'Callback', @obj.onToggleAxes);
            uicontrol(obj.ui.plot,...
                'Style', 'check',...
                'String', 'Grid',...
                'TooltipString', 'Toggle axis grid',...
                'Value', 1,...
                'Callback', @obj.onToggleGrid);
            uicontrol(obj.ui.plot,...
                'Style', 'text',...
                'String', 'Opacity',...
                'TooltipString', 'Set render transparency');
            uicontrol(obj.ui.plot,...
                'Style', 'check',...
                'String', 'Invert',...
                'TooltipString', 'Invert figure background',...
                'Callback', @obj.onToggleInvert);
            uicontrol(obj.ui.plot,...
                'Style', 'check',...
                'String', 'Lights',...
                'Value', 1,...
                'TooltipString', 'Turn lights on and off',...
                'Callback', @obj.onToggleLights);
            uicontrol(obj.ui.plot,...
                'Style', 'slider',...
                'Min', 0, 'Max', 1,...
                'SliderStep', [0.1 0.25],...
                'Value', 1,...
                'Callback', @obj.setOpacity);
            set(obj.ui.plot, 'Heights', [-1 -1 -1], 'Widths', [-1 -1]);
            
            % Disable until new neuron is imported
            set(obj.ui.plot.Children, 'Enable', 'off');
            
            set(obj.ui.root, 'Heights', [-.5 -5 -1.5 -.5 -1.5]);
            
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
        
        function row = emptyTableData(obj)
            % EMPTYTABLEDATA  Generate table data when there are no neurons
            row = {false, 0, obj.setLegendCell([1 1 1])};
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
        
        function str = formatCoordinates(pos, ds)
            % FORMATCOORDINATES  Sets coordinates to paste into Viking
            if nargin < 2
                ds = 2;
            end
            str = sprintf('X: %.1f Y: %.1f Z: %u DS: %u',...
                pos(1), pos(2), round(pos(3)), ds);
        end
        
        function str = getInstructions()
            % GETINSTRUCTIONS  Return instructions as multiline string
            str = sprintf(['NAVIGATION CONTROLS:\n',...
                '\nROTATE: arrow keys\n',...
                '   Azimuth: left, right\n',...
                '   Elevation: up, down\n',...
                '\nZOOM: ''z''\n',...
                '   To switch directions, press SHIFT+Z once\n',...
                '\nPAN:\n',...
                '   X-axis: ''a'' and ''d''\n',...
                '   Y-axis: ''q'' and ''e''\n',...
                '\nRESET axis: ''m''\n',...
                '   Z-axis: ''w'' and ''s''\n',...
                '\nCOPY location to clipboard:\n'...
                '   Click on figure then press ''c''\n',...
                '\nHELP: ''h''\n',...
                '\n\n',...
                'NEURON TABLE\n',...
                '- Checkboxes toggle render visibility\n',...
                '- Click color cell to change render color\n']);
        end
    end
end