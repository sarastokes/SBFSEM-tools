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
    %   RENDERAPP
    % ---------------------------------------------------------------------

    properties
        neuron
        source
        ax
        tbl
        ui
        figureHandle
        dataCursor
        offedges
    end

    properties (SetAccess = private)
        segments
        idMap
        hasSynapses
    end

    properties (Access = private, Transient = true)
        azel = [-37.5, 30];
        zoomFac = 0.9;
        panFac = 0.02;
        colorMap = 'cubicl';
    end

    properties (Constant = true, Hidden = true)
        COLORMAPS = {'parula','hsv','cubicl','viridis','redblue','haxby'};
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

            obj.hasSynapses = false;
            [~, obj.segments, obj.idMap] = dendriteSegmentation(obj.neuron);
            obj.createUi();
        end
    end

    methods (Access = private)
        function onClickMode(obj, ~, ~)
            % ONCLICKMODE  Enable or disable data tips

            switch obj.dataCursor.Enable
                case 'on'
                    obj.dataCursor.removeAllDataCursors();
                    set(obj.dataCursor, 'Enable', 'off');                    
                case 'off'
                    set(obj.dataCursor, 'Enable', 'on');
            end
            % c = getCursorInfo(obj.dataCursor);
        end

        function txt = onUpdateCursor(obj, ~, evt)
            % ONUPDATECURSOR  Custom data tip display callback
            pos = get(evt,'Position');
            locID = obj.getIDfromXYZ(pos, str2double(evt.Target.Tag));
            txt = {['ID: ' num2str(locID)],...
                ['X: ', num2str(pos(1))],...
                ['Y: ', num2str(pos(2))],...
                ['Z: ', num2str(pos(3))]};
        end

        function onCheckedColorSegments(obj, src, ~)
            % ONCOLORSEGMENTS  Randomly color to distinguish segments
            if src.Value == 1
                obj.colorSegments();
            else
                set(findall(obj.ax, 'Type', 'line'), 'Color', 'k');
            end
        end

        function onIncludeSynapses(obj, src, ~)
            % ONINCLUDESYNAPSES  Download synapses or toggle visibility
            if src.Value == 1
                if obj.hasSynapses
                    % Toggle visibility
                    names = obj.neuron.synapseNames;
                    for i = 1:numel(names)
                        set(findall(obj.ax, 'Tag', char(names(i))),...
                            'Visible', 'on');
                    end
                else
                    obj.fetchSynapses();
                end
            else
                names = obj.neuron.synapseNames;
                for i = 1:numel(names)
                    set(findall(obj.ax, 'Tag', char(names(i))),...
                        'Visible', 'off');
                end
            end
        end

        function onCheckOffEdges(obj, src, ~)
            % ONCHECKOFFEDGES
            if src.Value == 1
                if isempty(obj.offedges)
                    row = obj.neuron.nodes.OffEdge == 1;
                    T = obj.neuron.nodes(row,:);
                    obj.offedges = [];
                    for i = 1:height(T)
                        xyz = T.XYZum;
                        IDs = T.IDs;
                    end
                end
            else
            end
        end

        function onSelectedMarkerType(obj, src, ~)
            % ONSELECTEDMARKERTYPE  Change node markers

            switch src.Value
                case 1 % Normal
                    set(findall(obj.ax, 'Color', 'k'),...
                        'MarkerSize', 8);
                case 2 % Minimal
                    set(findall(obj.ax, 'Color', 'k'),...
                        'MarkerSize', 2);
                case 3 % True
                    warning('True size not yet implemented');
            end
        end

        function onChangeColormap(obj, src, ~)
            % ONCHANGECOLORMAP  Change colormap

            obj.colorMap = src.String{src.Value};
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
    end

    methods (Access = private)
        function colorSegments(obj)
            % COLORSEGMENTS  Assign each segment a different color

            tags = get(findall(obj.ax, 'Type', 'line'), 'Tag');
            % Randomize so neighboring segments appear distinct
            ind = randperm(numel(tags));
            cmap = obj.getColormap(numel(ind));
            for i = 1:numel(tags)
                set(findall(obj.ax, 'Tag', tags{i}),...
                    'Color', cmap(ind(i),:,:));
            end
        end

        function cmap = getColormap(obj, N)
            % GETCOLORMAP  Phase in sbfsem.ui.ColorMaps later
            switch obj.colorMap
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

        function locID = getIDfromXYZ(obj, xyz, segmentID)
            % GETIDFROMXYZ
            T = obj.segments(segmentID, :);
            IDs = cell2mat(T.ID);
            [~, ind] = ismember(xyz, cell2mat(T.XYZum), 'rows', 'legacy');
            locID = obj.idMap(IDs(ind));
        end

        function createUi(obj)
            % CREATEUI  Initial setup of user interface
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
            
            mainLayout = uix.HBox('Parent', graphTab,...
                'BackgroundColor', 'w');
            tablePanel = uipanel('Parent', tableTab);

            % Create the user interface panel
            obj.ui.root = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5, 'Padding', 5);
            obj.ui.source = uicontrol(obj.ui.root,...
                'Style', 'text',...
                'String', obj.source);
            obj.ui.dcm = uicontrol(obj.ui.root,...
                'Style', 'push',...
                'String', 'Data Cursor',...
                'Tooltip', 'Select individual nodes',...
                'Callback', @obj.onClickMode);
            obj.ui.markerType = uicontrol(obj.ui.root,...
                'Style', 'popup',...
                'String', {'Normal', 'Minimal'},...
                'Value', 2,...
                'Callback', @obj.onSelectedMarkerType);
            obj.ui.synapses = uicontrol(obj.ui.root,...
                'Style', 'checkbox',...
                'String', 'Include synapses',...
                'Value', 0,...
                'Callback', @obj.onIncludeSynapses);
            % obj.ui.offedges = uicontrol(obj.ui.root,...
            %    'Style', 'checkbox',...
            %    'String', 'Show off edges',...
            %    'Callback', @obj.onCheckOffEdges);
            obj.ui.colorSeg = uicontrol(obj.ui.root,...
                'Style', 'checkbox',...
                'String', 'Color segments',...
                'Value', 0,...
                'Callback', @obj.onCheckedColorSegments);
            obj.ui.colorMap = uicontrol(obj.ui.root,...
                'Style', 'popup',...
                'String', obj.COLORMAPS,...
                'Callback', @obj.onChangeColormap);

            % Data cursor mode requires parent with pixel property
            % Use Matlab's uipanel between axes and HBoxFlex
            hp = uipanel('Parent', mainLayout,...
                'BackgroundColor', 'w');
            obj.ax = axes('Parent', hp);
            
            % Setup the table view
            pos = get(obj.figureHandle, 'Position');
            obj.tbl = uitable('Parent', tablePanel,...
                'Data', table2cell(obj.neuron.nodes(:, {'ID', 'ParentID',...
                    'VolumeX', 'VolumeY', 'Z', 'Radius', 'OffEdge', 'Terminal'})),...
                'ColumnName', {'ID', 'ParentID', 'X', 'Y', 'Z',...
                    'Radius', 'OffEdge', 'Terminal'});
            set(obj.tbl, 'Position', [obj.MARGIN, obj.MARGIN, ...
                pos(3)-obj.MARGIN*2, pos(4)-obj.MARGIN*2]);
            
            set(mainLayout, 'Widths', [-1 -5]);

            if ~isempty(obj.neuron)
                obj.segmentPlot();
            end

            hold(obj.ax, 'on');
            axis(obj.ax, 'equal', 'tight');
            view(obj.ax, 3);
            grid(obj.ax, 'on');
        end

        function segmentPlot(obj)
            % SEGMENTPLOT  Plot each segment individually with ID tag
            for i = 1:height(obj.segments)
                xyz = cell2mat(obj.segments{i, 'XYZum'});
                line('XData', xyz(:,1),...
                    'YData', xyz(:,2),...
                    'ZData', xyz(:,3),...
                    'Parent', obj.ax,...
                    'Marker', '.',...
                    'MarkerSize', 2,...
                    'LineWidth', 1,...
                    'Color', 'k',...
                    'Tag', num2str(i));
                hold(obj.ax, 'on');
            end
        end

        function fetchSynapses(obj)
            % FETCHSYNAPSES  Get the unqiue synapses to plot
            names = obj.neuron.synapseNames();
            T = obj.neuron.getSynapseNodes();

            for i = 1:numel(names)
                xyz = obj.neuron.getSynapseXYZ(names(i));
                line('XData', xyz(:, 1),...
                    'YData', xyz(:, 2),...
                    'ZData', xyz(:, 3),...
                    'Parent', obj.ax,...
                    'Marker', '.',...
                    'MarkerSize', 10,...
                    'MarkerFaceColor', names(i).StructureColor,...
                    'MarkerEdgeColor', names(i).StructureColor,...
                    'LineStyle', 'none',...
                    'Tag', char(names(i)));
            end
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
    end
end

