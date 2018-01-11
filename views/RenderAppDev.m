classdef RenderAppDev < handle
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
    
    properties (Access = public)
        neurons             % Neuron objects
        IDs                 % IDs of neuron objects
        source              % Volume name
        volumeScale         % Volume dimensions (nm/pix)
        
        figureHandle        % Parent figure handle
        ui                  % UI panel handles
        ax                  % Render axis
        neuronTree
        mosaic
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
        function obj = RenderAppDev(source, shiftXY)
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
        function onAddNeuron(obj, ~, ~)
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
                % Update user on program status
                set(obj.ui.status, 'String', sprintf('Adding c%u', newID));
                drawnow;
                
                obj.addNeuron(newID);
                
                newColor = findall(obj.ax, 'Tag', obj.id2tag(newID));
                newColor = get(newColor(1), 'FaceColor');
                
                obj.addNeuronNode(newID, newColor);
                set(obj.ui.status, 'String', ' ');
                % Update the plot after each neuron imports
                drawnow;
            end
        end
        
        function onKeyPress(obj, ~, eventdata)
            % ONKEYPRESS  Control plot view with keyboard
            %
            % See also: AXDRAG
            switch eventdata.Character
                case 'h' % help
                    obj.openHelpDlg();
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
        
        function onToggleGrid(obj, src, ~)
            % TOGGLEGRID  Show/hide the grid
            if isempty(strfind(src.Label, 'off'))
                grid(obj.ax, 'on');
                src.Label = 'Grid off';
            else
                grid(obj.ax, 'off');
                src.Label = 'Grid on';
            end
        end
        
        function onToggleAxes(obj, src, ~)
            % ONTOGGLEAXES  Show/hide axes
            newColor = 'k';
            if obj.isInverted && isempty(strfind(src.Label,'on'))
                newColor = 'w';
            elseif ~obj.isInverted && isempty(strfind(src.Label, 'off'))
                newColor = 'w';
            end
            set(obj.ax, 'XColor', newColor,...
                'YColor', newColor, 'ZColor', newColor);
        end
        
        function onToggleLights(obj, src, ~)
            % ONTOGGLELIGHTS  Turn lighting on/off
            if isempty(strfind(src.Label, '2D'))
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'gouraud');
                src.Label =  'Show as 2D';
            else
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'none');
                src.Label = 'Show in 3D';
            end
        end
        
        function onToggleInvert(obj, src, ~)
            % ONINVERT  Invert figure colors
            if ~obj.isInverted
                bkgdColor = 'k'; frgdColor = 'w';
                set(obj.ax, 'GridColor', [0.85, 0.85, 0.85]);
                obj.isInverted = true;
                src.Label = 'Light background';
            else
                bkgdColor = 'w'; frgdColor = 'k';
                set(obj.ax, 'GridColor', [0.15 0.15 0.15]);
                obj.isInverted = true;
                src.Label = 'Dark background';
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
        
        function onExportImage(obj, src, ~)
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
            
            if isempty(strfind(src.Label, 'high res'))
                print(newAxes.Parent, [fPath, fName], exten);
            else
                print(newAxes.Parent, [fPath, fName], exten, '-r600');
            end
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

        function openHelpDlg(obj, ~, ~)
             helpdlg(obj.getInstructions, 'RenderApp Instructions');
        end

        function onNextColor(obj, src, ~)
            % Open UI to choose new color, reflect change in table
            newColor = selectcolor('hCaller', obj.figureHandle);
            if numel(newColor) == 3
                set(src, 'BackgroundColor', newColor);
            end
        end

        function onChangeColor(obj, ~, evt)
            assignin('base', 'colorevt', evt);
            newColor = selectcolor('hCaller', obj.figureHandle);
            if isempty(newColor)
                return;
            end
            % Get the target ID and neuron
            set(findall(obj.ax, 'Tag', evt.Source.Tag),...
                'FaceColor', newColor);
            % TODO: set icon
        end

        function onOpenView(obj, src, ~)
            neuron = obj.neurons(evt.Source.Tag(1:end-1));
            
            switch src.Label
                case 'Node View'
                    NodeView(neuron);
                case 'Stratification View'
                    StratificationView(neuron);
                case 'Soma Distance View'
                    SomaDistanceView(neuron);
            end
        end
        
        function onImportCones(obj, src, ~)
            % ONIMPORTCONES  
            if isempty(obj.mosaic)
                obj.mosaic = sbfsem.ConeMosaic('i');
            end
            switch src.Label
                case 'All cones'
                    obj.mosaic.plot('LM', obj.ax, 'LM');
                    obj.mosaic.plot('S', obj.ax, 'S');
                case 'LM-cones'
                    obj.mosaic.plot('LM', obj.ax, 'LM');
                case 'S-cones'
                    obj.mosaic.plot('S', obj.ax, 'S');
            end
        end
    end
    
    methods (Access = private)
        function addNeuron(obj, newID)
            % ADDNEURON  Add a new neuron and render
            
            disp(['Importing new neuron ', num2str(newID)]);
            neuron = Neuron(newID, obj.source, obj.SYNAPSES, obj.shiftXY);
            % Build the 3D model
            set(obj.ui.status, 'String', sprintf('Rendering c%u', newID));
            drawnow;
            neuron.build();
            % Render the neuron
            neuron.render('ax', obj.ax,...
                'FaceColor', obj.ui.nextColor.BackgroundColor);
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
                'Name', 'RenderApp - SARA DEV VERSION',...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'KeyPressFcn', @obj.onKeyPress);
            
            mh.prefs = uimenu('Parent', obj.figureHandle,...
                'Label', 'Plot Modifiers');
            uimenu('Parent', mh.prefs,...
                'Label', 'Dark background',...
                'Callback', @obj.onToggleInvert);
            uimenu('Parent', mh.prefs,...
                'Label', 'Axes off',...
                'Callback', @obj.onToggleAxes);
            uimenu('Parent', mh.prefs,...
                'Label', 'Grid off',...
                'Callback', @obj.onToggleGrid);
            uimenu('Parent', mh.prefs,...
                'Label', 'Show as 2D',...
                'Callback', @obj.onToggleLights);
            mh.import = uimenu('Parent', obj.figureHandle,...
                'Label', 'Import');
                mh.cone = uimenu('Parent', mh.import,...
                    'Label', 'Cone Mosaic');
                    uimenu('Parent', mh.cone,...
                        'Label', 'All cones',...
                        'Callback', @obj.onImportCones);
                    uimenu('Parent', mh.cone,...
                        'Label', 'LM-cones',...
                        'Callback', @obj.onImportCones);
                    uimenu('Parent', mh.cone,...
                        'Label', 'S-cones',...
                        'Callback', @obj.onImportCones);
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
                    'Label', 'Export as image (high res)',...
                    'Callback', @obj.onExportImage);
                uimenu('Parent', mh.export,...
                    'Label', 'Export as COLLADA',...
                    'Callback', @obj.onExportCollada);
                uimenu('Parent', mh.export,...
                    'Label', 'Send neurons to workspace',...
                    'Callback', @obj.onExportNeuron);
            mh.align = uimenu('Parent', obj.figureHandle,...
                'Label', 'Align');
                uimenu('Parent', mh.align,...
                    'Label', 'Bridge infmonkey gaps');
            uimenu('Parent', obj.figureHandle,...
                'Label', 'Help',...
                'Callback', @obj.openHelpDlg);
            
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
            obj.neuronTree = uiextras.jTree.CheckboxTree(...
                'Parent', obj.ui.root,...
                'RootVisible', false,...
                'CheckboxClickedCallback', @obj.onNodeChecked);
            
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
                'TooltipString', 'Input ID(s) separated by commas',...
                'String', '');
            buttonLayout = uix.VBox('Parent', pmLayout,...
                'BackgroundColor', 'w');
            obj.ui.add = uicontrol(buttonLayout,...
                'Style', 'push',...
                'String', '+',...
                'FontWeight', 'bold',...
                'FontSize', 20,...
                'TooltipString', 'Add neuron(s) in editbox',...
                'Callback', @obj.onAddNeuron);
            obj.ui.nextColor = uicontrol(buttonLayout,...
                'Style', 'push',...
                'String', ' ',...
                'BackgroundColor', [0.5 0 0.8],...
                'TooltipString', 'Click to change next neuron color',...
                'Callback', @obj.onNextColor);
            set(buttonLayout, 'Heights', [-1.2 -.8])
            set(pmLayout, 'Widths', [-1.2, -0.8])
            
            % Plot modifiers
            obj.ui.status = uicontrol(obj.ui.root,...
                'Style', 'text',...
                'String', ' ',...
                'FontAngle', 'italic');
            obj.ui.plot = uix.HBox('Parent', obj.ui.root);
            uicontrol(obj.ui.plot,...
                'Style', 'text',...
                'String', 'Opacity',...
                'TooltipString', 'Set render transparency');
            uicontrol(obj.ui.plot,...
                'Style', 'slider',...
                'Min', 0, 'Max', 1,...
                'SliderStep', [0.1 0.25],...
                'Value', 1,...
                'Callback', @obj.setOpacity);
            
            % Disable until new neuron is imported
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
        
        function newNode = addNeuronNode(obj, ID, rgb, hasSynapses)
            if nargin < 4
                hasSynapses = false;
            end
            % if nargin < 3
            %     rgb = [1 1 1];
            % end
            newNode = uiextras.jTree.CheckboxTreeNode(...
                'Parent', obj.neuronTree,...
                'Name', obj.id2tag(ID),...
                'Checked', true);
            assignin('base', 'newNode', newNode);
            % Legend Icon
            % iconImage = cat(3, rgb(1) * ones(16,16),...
            %     rgb(2)*ones(16,16), rgb(3)*ones(16,16));
            % setIcon(newNode, im2java(iconImage));
            
            c = uicontextmenu('Parent', obj.figureHandle);
                uimenu(c,...
                    'Label', 'Update',...
                    'Callback', @obj.onUpdateNeuron,...
                    'Tag', obj.id2tag(ID));
                uimenu(c,...
                    'Label', 'Remove Neuron',...
                    'Callback', @obj.onRemoveNeuron,...
                    'Tag', obj.id2tag(ID));
                uimenu(c,...
                    'Label', 'Change Color',...
                    'Callback', @obj.onChangeColor,...
                    'Tag', obj.id2tag(ID));
                v = uimenu(c, 'Label', 'Open view');
                    uimenu(v, 'Label', 'Node View',...
                        'Callback', @obj.onOpenView, 'Tag', obj.id2tag(ID));
                    uimenu(v, 'Label', 'Stratification View',...
                        'Callback', @obj.onOpenView, 'Tag', obj.id2tag(ID));
                    uimenu(v, 'Label', 'Soma Distance View',...
                        'Callback', @obj.onOpenView, 'Tag', obj.id2tag(ID));
            
            if ~hasSynapses
                uimenu(c, 'Label', 'Get Synapses',...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onGetSynapses);
            else
                neuron = obj.neurons(ID);
                synapseNames = neuron.synapseNames;
                for i = 1:numel(synapseNames)
                    obj.addSynapseNode(newNode, synapseNames{i});
                end
            end
            set(newNode, 'UIContextMenu', c);
        end
        
        function onUpdateNeuron(obj, ~, evt)
            % ONUPDATENEURON
            
            % Get the target ID and neuron
            ID = obj.tag2id(evt.Source.Tag);
            neuron = obj.neurons(num2str(ID));
            % Update the OData and the 3D model
            neuron.update();
            neuron.model();
            % Delete the old one and render a new one
            patches = findall(obj.ax, 'Tag', evt.Source.Tag);
            oldColor = get(patches, 'FaceColor');
            delete(patches);
            disp('RENDERAPP: Rendering updated model');
            neuron.render('ax', obj.ax, 'FaceColor', oldColor);
        end
        
        function onNodeChecked(obj, ~, evt)
            % ONNODECHECKED  Toggles visibility of patches
            
            if isempty(evt.SelectionPaths)
                % No nodes are checked
                set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
            elseif numel(evt.SelectionPaths) == 1
                if strcmp(evt.SelectionPaths.Name, 'Root')
                    % All nodes are checked
                    set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'on');
                else % Only one node is checked
                    set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
                    set(findall(obj.ax, 'Tag', evt.SelectionPaths(1).Name),...
                        'Visible', 'on');
                end
            elseif numel(evt.SelectionPaths) > 1
                % Some but not all nodes are checked
                set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
                for i = 1:numel(evt.SelectionPaths)
                    set(findall(obj.ax, 'Tag', evt.SelectionPaths(i).Name),...
                        'Visible', 'on');
                end
            end
        end
        
        function onGetSynapses(~, ~, ~)
            % uicontextmenu callback
        end
        
        function onRemoveNeuron(~, ~, ~)
            % uicontextmenu callback
        end
    end
    
    methods (Static = true)
        function newNode = addSynapseNode(parentNode, synapseName)
            % ADDSYNAPSENODE
            newNode = uiextras.jTree.CheckboxTreeNode(...
                'Name', char(synapseName),...
                'Parent', parentNode);
        end
        
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
        
        function id = tag2id(tag)
            % TAG2ID  Quick fcn for ('c127' -> 127)
            id = str2double(tag(2:end));
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