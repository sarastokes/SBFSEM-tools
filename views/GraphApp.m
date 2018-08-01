classdef GraphApp < handle
    % GRAPHAPP
    %
    % Description:
    %   Interact with annotations as nodes and edges of a graph
    %
    % Constructor:
    %   GraphApp(NEURON, SOURCE)
    %   where NEURON is a Neuron obj or ID for neuron in SOURCE
    %
    % TODO:
    %   - Integration with ChecklistView
    %
    % History:
    %   9Jul2018 - Added data table and help panel
    %
    % See also:
    %   RENDERAPP, NODEVIEW
    % ---------------------------------------------------------------------
    
    properties
        neuron
        source
        ax
        ui
        figureHandle
        dataCursor
        segments
    end
    
    properties (Dependent = true, Hidden = true)
        cmap
        surfaceAlpha
        hasSynapses
        showSegments
        showSurface
        showSynapses
        showOffEdges
        showTerminals
    end
    
    properties (Access = private, Transient = true)
        azel = [-37.5, 30];
        zoomFac = 0.9;
        panFac = 0.02;
        doSurface = true;
    end
    
    properties (Constant = true, Hidden = true)
        COLORMAPS = {'parula', 'hsv', 'cubicl', 'viridis', 'redblue', 'haxby'};
        SOURCES = {'NeitzTemporalMonkey','NeitzInferiorMonkey','MarcRC1'};
        MARGIN = 40;
    end
    
    methods
        function obj = GraphApp(neuron, source)
            % GRAPHAPP
            if nargin == 2
                obj.source = validateSource(source);
                obj.neuron = Neuron(neuron, obj.source);
            elseif nargin == 1
                obj.neuron = neuron;
                obj.source = neuron.source;
            elseif nargin == 0
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
            
            import sbfsem.render.*;
            obj.segments = sbfsem.render.Segment(obj.neuron);
            obj.createUi();
        end
    end
    
    % Dependent set/get methods
    methods
        function hasSynapses = get.hasSynapses(obj)
            hasSynapses = ~isempty(obj.neuron.synapses);
        end
        
        function cmap = get.cmap(obj)
            h = findobj(obj.figureHandle, 'Tag', 'CMapMenu');
            cmap = h.String{h.Value};
        end
        
        function showSegments = get.showSegments(obj)
            h = findall(obj.figureHandle, 'Tag', 'ShowSegments');
            showSegments = logical(h.Value);
        end
        
        function showSurface = get.showSurface(obj)
            h = findall(obj.figureHandle, 'Tag', 'ShowSurface');
            showSurface = logical(h.Value);
        end
        
        function showSynapses = get.showSynapses(obj)
            h = findall(obj.figureHandle, 'Tag', 'ShowSynapses');
            showSynapses = logical(h.Value);
        end
        
        function showOffEdges = get.showOffEdges(obj)
            h = findobj(obj.figureHandle, 'Tag', 'ShowOffEdges');
            showOffEdges = logical(h.Value);
        end
        
        function showTerminals = get.showTerminals(obj)
            h = findobj(obj.figureHandle, 'Tag', 'ShowTerminals');
            showTerminals = logical(h.Value);
        end
    end
    
    % Helper functions
    methods (Access = private)
        function colorSegments(obj)
            % COLORSEGMENTS  Assign each segment a different color
            
            tags = get(findall(obj.ax, 'Type', 'line'), 'Tag');
            % Randomize so neighboring segments appear distinct
            ind = randperm(numel(tags));
            if numel(ind) > 256
                cdata = obj.getColormap(obj.cmap, 256);
                cdata = cat(1, cdata, cdata);
            else
                cdata = obj.getColormap(obj.cmap, numel(ind));
            end
            for i = 1:numel(tags)
                set(findall(obj.ax, 'Tag', tags{i}),...
                    'Color', cdata(ind(i),:,:));
            end
        end
        
        function locID = id2xyz(obj, xyz, segmentID)
            % GETIDFROMXYZ
            T = obj.segments.segmentTable(segmentID, :);
            IDs = cell2mat(T.ID);
            [~, ind] = ismember(xyz, cell2mat(T.XYZum), 'rows', 'legacy');
            locID = obj.segments.nodeIDs(IDs(ind));
        end
        
        function plotSegments(obj)
            % SEGMENTPLOT  Plot each segment individually with ID tag
            for i = 1:height(obj.segments.segmentTable)
                xyz = cell2mat(obj.segments.segmentTable{i, 'XYZum'});
                line(obj.ax, xyz(:,1), xyz(:,2), xyz(:,3),...
                    'Marker', '.', 'MarkerSize', 2,...
                    'LineWidth', 1, 'Color', 'k',...
                    'Tag', num2str(i));
            end
        end
        
        function plotCylinders(obj)
            % CYLINDERPLOT  Plot the structure around each point
            for i = 1:height(obj.segments.segmentTable)
                % Generate cylinder coordinates with correct radii
                radii = cell2mat(obj.segments.segmentTable{i, 'Rum'});
                [X, Y, Z] = cylinder(radii);
                % Translate the cylinder points by annotation XYZ
                xyz = cell2mat(obj.segments.segmentTable{i, 'XYZum'});
                Z = repmat(xyz(:, 3), [1, size(Z, 2)]);
                % The PickableParts setting ensures surfaces are invisible
                % in datacursormode.
                s = surf(obj.ax, X+xyz(:, 1), Y+xyz(:,2), Z,...
                    'FaceAlpha', 0.3,...`
                    'EdgeColor', 'none',...
                    'PickableParts', 'none',...
                    'Tag', ['s', num2str(i)]);
                if ~obj.showSurface
                    set(s, 'Visible', 'off');
                end
                hold(obj.ax, 'on');
            end
            axis(obj.ax, 'equal', 'tight');
        end
        
        function plotSynapses(obj)
            % SYNAPSEPLOT  Get the unqiue synapses to plot
            
            if ~obj.hasSynapses
                return
            end
            
            names = obj.neuron.synapseNames();
            
            for i = 1:numel(names)
                xyz = obj.neuron.getSynapseXYZ(names(i));
                h = line(obj.ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                    'Marker', '.', 'MarkerSize', 10,...
                    'MarkerFaceColor', names(i).StructureColor,...
                    'MarkerEdgeColor', names(i).StructureColor,...
                    'LineStyle', 'none',...
                    'Tag', 'Synapse');
                if ~obj.showSynapses
                    set(h, 'Visible', 'off');
                end
            end
        end
        
        function plotOffEdges(obj)
            % OFFEDGEPLOT  Plot nodes marked as unfinished
            
            % Delete any existing off edge nodes
            delete(findall(obj.figureHandle, 'Tag', 'OffEdge'));
            % Get OffEdge node IDs
            offEdgeIDs = obj.neuron.offEdges;
            % Return if no off edges in neuron
            if isempty(offEdgeIDs)
                return;
            end
            
            xyz = obj.neuron.id2xyz(offEdgeIDs);
            h = line(obj.ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                'Marker', '.', 'MarkerSize', 12,...
                'MarkerFaceColor', 'r',...
                'MarkerEdgeColor', 'r',...
                'LineStyle', 'none',...
                'Tag', 'OffEdge');
            if ~obj.showOffEdges
                set(h, 'Visible', 'off');
            end
        end
        
        function plotTerminals(obj)
            % PLOTTERMINALS  Plot nodes marked as terminals
            % Delete any existing off edge nodes
            delete(findall(obj.figureHandle, 'Tag', 'Terminal'));
            % Get OffEdge node IDs
            terminalIDs = obj.neuron.terminals;
            % Return if no off edges in neuron
            if isempty(terminalIDs)
                return;
            end
            
            xyz = obj.neuron.id2xyz(terminalIDs);
            h = line(obj.ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                'Marker', '.', 'MarkerSize', 12,...
                'MarkerFaceColor', 'b',...
                'MarkerEdgeColor', 'b',...
                'LineStyle', 'none',...
                'Tag', 'Terminal');
            if ~obj.showTerminals
                set(h, 'Visible', 'off');
            end
        end
    end
    
    % Callback functions
    methods (Access = private)
        function onUpdateNeuron(obj, ~, ~)
            % ONUPDATENEURON
            
            % Update the neuron OData
            obj.neuron.update();
            
            % Delete the old plot components
            delete(findall(obj.figureHandle, 'Type', 'surface'));
            delete(findall(obj.figureHandle, 'Type', 'line'));
            
            % Recreate plot components
            obj.plotSegments();
            if obj.doSurface
                obj.plotCylinders();
            end
            obj.plotOffEdges();
            obj.plotTerminals();
            obj.plotSynapses();
        end
        
        function onClickMode(obj, ~, ~)
            % ONCLICKMODE  Enable or disable data tips
            
            switch obj.dataCursor.Enable
                case 'on'
                    obj.dataCursor.removeAllDataCursors();
                    set(obj.dataCursor, 'Enable', 'off');
                    set(findobj(obj.figureHandle, 'Tag', 'DCBox'),...
                        'BackgroundColor', 'w',...
                        'TooltipString', 'Select individual nodes');
                case 'off'
                    set(obj.dataCursor, 'Enable', 'on');
                    set(findobj(obj.figureHandle, 'Tag', 'DCBox'),...
                        'BackgroundColor', [0.65, 0.65, 0.65],...
                        'TooltipString', 'Turn Data Cursor mode off');
            end
        end
        
        function txt = onUpdateCursor(obj, ~, evt)
            % ONUPDATECURSOR  Custom data tip display callback
            pos = get(evt,'Position');
            switch evt.Target.Tag
                case 'OffEdge'
                    xyz = obj.neuron.id2xyz(obj.neuron.offEdges);
                    ind = find(sum(pos, 2) == sum(xyz, 2));
                    locID = obj.neuron.offEdges(ind); %#ok
                case 'Synapse'
                otherwise
                    locID = obj.id2xyz(pos, str2double(evt.Target.Tag));
            end
            txt = {['ID: ' num2str(locID)],...
                ['X: ', num2str(pos(1))],...
                ['Y: ', num2str(pos(2))],...
                ['Z: ', num2str(pos(3))]};
        end
        
        function onSelectedMarkerType(obj, src, ~)
            % ONSELECTEDMARKERTYPE  Change node markers
            
            switch src.Value
                case 1 % Minimal
                    set(findall(obj.ax, 'Color', 'k'),...
                        'MarkerSize', 2);
                case 2 % Medium
                    set(findall(obj.ax, 'Color', 'k'),...
                        'MarkerSize', 7);
                case 3 % Large
                    set(findall(obj.ax, 'Color', 'k'),...
                        'MarkerSize', 10);
            end
        end
        
        function onChangeColormap(obj, ~, ~)
            % ONCHANGECOLORMAP  Change colormap
            
            h = findobj(obj.figureHandle, 'Tag', 'ShowSegments');
            if h.Value == 1
                obj.colorSegments();
            end
            set(obj.figureHandle, 'Colormap', obj.cmap);
            
            % TODO: add colormap to surface
        end
        
        function onKeyPress(obj, ~, eventdata)
            % ONKEYPRESS  Control plot view with keyboard
            %
            % See also: AXDRAG
            switch eventdata.Character
                case 'h' % help
                    helpdlg(obj.getInstructions, 'GraphApp Instructions');
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
                otherwise
                    return;
            end
            view(obj.ax, obj.azel);
        end
        
        function onCheckedColorSegments(obj, src, ~)
            % ONCOLORSEGMENTS  Randomly color to distinguish segments
            if src.Value == 1
                obj.colorSegments();
            else
                set(findall(obj.ax, 'Type', 'line'), 'Color', 'k');
            end
        end
        
        function onShowSynapses(obj, src, ~)
            % ONINCLUDESYNAPSES  Download synapses or toggle visibility
            if src.Value == 1
                if obj.hasSynapses
                    % Toggle visibility
                    set(findall(obj.ax, 'Tag', 'Synapse'), 'Visible', 'on');
                else
                    obj.neuron.getSynapses();
                    obj.plotSynapses();
                end
            else
                names = obj.neuron.synapseNames;
                for i = 1:numel(names)
                    set(findall(obj.ax, 'Tag', 'Synapse'), 'Visible', 'off');
                end
            end
        end
        
        function onShowOffEdges(obj, src, ~)
            % ONSHOWOFFEDGES  Toggle unfinished branch markers
            if src.Value == 1
                set(findall(obj.ax, 'Tag', 'OffEdge'), 'Visible', 'on');
            else
                set(findall(obj.ax, 'Tag', 'OffEdge'), 'Visible', 'off');
            end
        end
        
        function onShowTerminals(obj, src, ~)
            % ONSHOWOFFEDGES  Toggle terminal branch markers
            if src.Value == 1
                set(findall(obj.ax, 'Tag', 'Terminal'), 'Visible', 'on');
            else
                set(findall(obj.ax, 'Tag', 'Terminal'), 'Visible', 'off');
            end
        end
        
        function onShowSurface(obj, src, ~)
            % ONSHOWSURFACE  Toggle visibility of 3D render
            h = findall(obj.figureHandle, 'Type', 'surface');
            if src.Value == 1
                set(h, 'Visible', 'on');
            else
                set(h, 'Visible', 'off');
            end
        end
    end
    
    % User interface initialization methods
    methods (Access = private)
        function createUi(obj)
            % CREATEUI  Initial setup of user interface
            LayoutManager = sbfsem.ui.LayoutManager;
            
            obj.figureHandle = figure(...
                'Name', 'GraphUI',...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'KeyPressFcn', @obj.onKeyPress);
            pos = get(obj.figureHandle, 'Position');
            set(obj.figureHandle, 'Position', [100, 100, pos(3)+100, pos(4)+100]);
            
            obj.dataCursor = datacursormode(obj.figureHandle);
            set(obj.dataCursor,...
                'Enable', 'off',...
                'UpdateFcn', @obj.onUpdateCursor);
            
            tabLayout = uitabgroup('Parent', obj.figureHandle);
            graphTab = uitab(tabLayout, 'Title', 'Graph');
            tableTab = uitab(tabLayout, 'Title', 'Table');
            helpTab = uitab(tabLayout, 'Title', 'Help');
            
            helpLayout = uix.VBox('Parent', helpTab,...
                'BackgroundColor', 'w');
            uicontrol('Parent', helpLayout,...
                'Style', 'text',...
                'String', obj.getInstructions());
            uix.Empty('Parent', helpLayout);
            set(helpLayout, 'Heights', [-1 -0.1]);
            
            mainLayout = uix.HBoxFlex('Parent', graphTab,...
                'BackgroundColor', 'w');
            tablePanel = uipanel('Parent', tableTab);
            
            % Create the user interface panel
            uiLayout = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', 'w');
            uicontrol(uiLayout, 'Style', 'text', 'String', obj.source);
            uicontrol(uiLayout,...
                'Style', 'push',...
                'String', 'Data Cursor',...
                'Tag', 'DCBox',...
                'Tooltip', 'Select individual nodes',...
                'Callback', @obj.onClickMode);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show synapses',...
                'Value', 0,...
                'Tag', 'ShowSynapses',...
                'TooltipString', 'Show synapse annotations',...
                'Callback', @obj.onShowSynapses);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show Surface',...
                'Value', 1,...
                'Tag', 'ShowSurface',...
                'TooltipString', 'Show 3D structure',...
                'Callback', @obj.onShowSurface);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Color segments',...
                'Value', 0,...
                'Tag', 'ShowSegments',...
                'TooltipString', 'Color by branch segment',...
                'Callback', @obj.onCheckedColorSegments);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show Unfinished',...
                'Value', 0,...
                'Tag', 'ShowOffEdges',...
                'TooltipString', 'Show nodes marked as unfinished',...
                'Callback', @obj.onShowOffEdges);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show Terminals',...
                'Value', 0,...
                'Tag', 'ShowTerminals',...
                'TooltipString', 'Show nodes marked as terminals',...
                'Callback', @obj.onShowTerminals);
            LayoutManager.verticalBoxWithLabel(uiLayout, 'Marker Size:',...
                'Style', 'popup',...
                'String', {'Minimal', 'Medium', 'Large'},...
                'Tag', 'NodeSize',...
                'TooltipString', 'Change annotation marker size',...
                'Callback', @obj.onSelectedMarkerType);
            LayoutManager.verticalBoxWithLabel(uiLayout, 'Colormap:',...
                'Style', 'popup',...
                'String', obj.COLORMAPS,...
                'Tag', 'CMapMenu',...
                'TooltipString', 'Set segment or cylinder color map',...
                'Callback', @obj.onChangeColormap);
            uicontrol(uiLayout,...
                'Style', 'push',...
                'String', 'Update Neuron',...
                'Tag', 'Update underlying annotation data',...
                'TooltipString', 'Update underlying neuron data',...
                'Callback', @obj.onUpdateNeuron);
            
            set(uiLayout, 'Heights',...
                [-0.5, -1, -0.5, -0.5, -0.5, -0.5, -0.5, -1, -1, -1]);
            
            % Data cursor mode requires parent with pixel property
            % Use Matlab's uipanel between axes and HBoxFlex
            hp = uipanel('Parent', mainLayout,...
                'BackgroundColor', 'w');
            obj.ax = axes('Parent', hp);
            obj.createPlot();
            
            % Setup the table view
            obj.createTable(tablePanel);
            
            set(mainLayout, 'Widths', [-1 -3.5]);
        end
        
        function createPlot(obj)
            % CREATEPLOT  Initialize axes
            hold(obj.ax, 'on');
            obj.plotSegments();
            try
                obj.plotCylinders();
            catch
                obj.doSurface = true;
                set(findobj(obj.figureHandle, 'Tag', 'ShowSurface'),...
                    'Enable', 'off');
                warning('Upgrade Matlab version to enable surface plots');
            end
            obj.plotOffEdges();
            obj.plotTerminals();
            obj.plotSynapses();
            
            axis(obj.ax, 'equal', 'tight');
            view(obj.ax, 3);
            grid(obj.ax, 'on');
        end
        
        function createTable(obj, parentHandle)
            % CREATETABLE  Initialize annotation table
            pos = get(obj.figureHandle, 'Position');
            locTable = uitable('Parent', parentHandle,...
                'Data', table2cell(obj.neuron.nodes(:, {'ID', 'ParentID',...
                'VolumeX', 'VolumeY', 'Z', 'Radius', 'OffEdge', 'Terminal'})),...
                'ColumnName', {'ID', 'ParentID', 'X', 'Y', 'Z',...
                'Radius', 'OffEdge', 'Terminal'});
            set(locTable, 'Position', [obj.MARGIN, obj.MARGIN, ...
                pos(3)-obj.MARGIN*2, pos(4)-obj.MARGIN*2]);
        end
    end
    
    methods (Static)
        function str = getInstructions()
            % GETINSTRUCTIONS  Return instructions as multiline string
            str = sprintf(['NAVIGATION CONTROLS:\n',...
                'ROTATE: arrow keys\n',...
                '   Azimuth: left, right\n',...
                '   Elevation: up, down\n',...
                'ZOOM: ''z''\n',...
                '   To switch directions, press SHIFT+Z once\n',...
                'PAN:\n',...
                '   X-axis: ''a'' and ''d''\n',...
                '   Y-axis: ''q'' and ''e''\n',...
                'RESET axis: ''m''\n',...
                '   Z-axis: ''w'' and ''s''\n',...
                'HELP: ''h''\n',...
                'DATA CURSOR:\n',...
                '   Use this to select individual nodes and show info\n',...
                '   about node ID and XYZ location']);
        end
        
        function cmap = getColormap(cmapName, N)
            % GETCOLORMAP  Phase in sbfsem.ui.ColorMaps later
            if nargin < 2
                N = 256;
            end
            
            switch lower(cmapName)
                % Matlab builtin
                case 'parula'
                    cmap = parula(N);
                case 'hsv'
                    cmap = hsv(N);
                    % Python matplotlib
                case 'viridis'
                    cmap = viridis(N);
                    % Perceptually distinct
                case 'cubicl'
                    cmap = pmkmp(N, 'CubicL');
                    % Bathymetry
                case 'haxby'
                    cmap = haxby(N);
                    % Light-Bertlein
                case 'redblue'
                    cmap = lbmap(N, 'RedBlue');
            end
        end
    end
end
