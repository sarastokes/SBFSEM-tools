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
    %   - Table view panel
    %   - Integration with ChecklistView
    %
    % Work in progress!
    % ---------------------------------------------------------------------
    
    properties
        neuron
        source
        ax
        ui
        figureHandle
        dataCursor
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
                warning('Implement dialog box for picking neuron');
                return;
            end
            
            obj.hasSynapses = false;
            [~, obj.segments, obj.idMap] = dendriteSegmentation(obj.neuron);
            obj.createUi();
        end
    end
    
    methods (Access = private)       
        function onClickMode(obj, ~, ~)
            % ONCLICKMODE  Enable data tips
            set(obj.dataCursor, 'Enable', 'on');
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
            % ONCHANGECOLORMAP
            obj.colorMap = src.String{src.Value};
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
            
            mainLayout = uix.HBox('Parent', obj.figureHandle,...
                'BackgroundColor', 'w');
            
            % Create the user interface panel
            obj.ui.root = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5, 'Padding', 5);
            obj.ui.source = uicontrol(obj.ui.root,...
                'Style', 'text',...
                'String', obj.source);
            obj.ui.dcm = uicontrol(obj.ui.root,...
                'Style', 'push',...
                'String', 'Data Cursor Mode',...
                'Callback', @obj.onClickMode);
            obj.ui.markerType = uicontrol(obj.ui.root,...
                'Style', 'popup',...
                'String', {'Normal', 'Minimal', 'True'},...
                'Value', 2,...
                'Callback', @obj.onSelectedMarkerType);
            obj.ui.synapses = uicontrol(obj.ui.root,...
                'Style', 'checkbox',...
                'String', 'Include synapses',...
                'Value', 0,...
                'Callback', @obj.onIncludeSynapses);
            obj.ui.offedges = uicontrol(obj.ui.root,...
                'Style', 'checkbox',... 
                'String', 'Show off edges',...
                'Callback', @obj.onCheckOffEdges);
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
                '\nHELP: ''h''\n']);
        end
    end
end

