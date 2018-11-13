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
    
    properties (Access = public)
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
        showUnfinished
        showTerminals
        showOffEdges
    end
    
    properties (Access = private, Transient = true)
        azel = [-37.5, 30];
        zoomFac = 0.9;
        panFac = 0.02;
        doSurface = true;
    end
    
    properties (Constant = true, Hidden = true)
        COLORMAPS = {'parula', 'winter', 'hsv', 'cubicl', 'viridis', 'redblue', 'haxby'};
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
    		else
    			[selection, selectedSource] = listdlg(...
    				'PromptString', 'Select a source:',...
    				'Name', 'GraphApp Source Selection',...
    				'SelectionMode', 'single',...
    				'ListString', obj.SOURCES);
    			if selectedSource
    				obj.source = obj.SOURCES{selection};
    				fprintf('Running with %s\n', obj.source);
    			else
    				warning('No source selected... exiting');
    				return;
    			end
                answer = inputdlg('Input cell ID', 'Neuron Dialog', 1, {''});
                if isempty(answer)
                    return;
                end
                ID = str2double(answer{1});
                obj.neuron = Neuron(ID, obj.source);
    		end

    		obj.segments = sbfsem.render.Segment(obj.neuron);
    		obj.createUi();
        end
    end
    
    % Dependent set/get methods
    methods
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
        
        function hasSynapses = get.hasSynapses(obj)
            hasSynapses = isprop(obj.neuron, 'synapses') && ~isempty(obj.neuron.synapses);
        end
        
        function showSynapses = get.showSynapses(obj)
            h = findall(obj.figureHandle, 'Tag', 'ShowSynapses');
            showSynapses = logical(h.Value);
        end
        
        function showUnfinished = get.showUnfinished(obj)
            h = findobj(obj.figureHandle, 'Tag', 'ShowUnfinished');
            showUnfinished = logical(h.Value);
        end
        
        function showTerminals = get.showTerminals(obj)
            h = findobj(obj.figureHandle, 'Tag', 'ShowTerminals');
            showTerminals = logical(h.Value);
        end

        function showOffEdges = get.showOffEdges(obj)
            h = findobj(obj.figureHandle, 'Tag', 'ShowOffEdges');
            showOffEdges = logical(h.Value);
        end
    end
    
    % Helper functions
    methods (Access = private)

        function [locID, sectionID] = id2xyz(obj, xyz, segmentID)
            % GETIDFROMXYZ
            T = obj.segments.segmentTable(segmentID, :);
            IDs = cell2mat(T.ID);
            [~, ind] = ismember(xyz, cell2mat(T.XYZum),...
                'rows', 'legacy');
            locID = obj.segments.nodeIDs(IDs(ind));
            % For speed, appending a 2nd output...
            Zs = cell2mat(T.Z);
            sectionID = Zs(ind);
        end 

        function updateStatus(obj, str)
            % UPDATESTATUS  Update status text
            if nargin < 2
                str = '';
            else
                assert(ischar(str), 'Status updates must be char');
            end
            set(findobj(obj.figureHandle, 'Tag', 'Status'), 'String', str);
            drawnow;
        end
           
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
        
        function plotUnfinished(obj)
            % PLOTUNFINISHED  Plot nodes marked as unfinished
            
            % Delete any existing off edge nodes
            delete(findall(obj.figureHandle, 'Tag', 'Unfinished'));
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
                'Tag', 'Unfinished');
            if ~obj.showUnfinished
                set(h, 'Visible', 'off');
            end
        end

        function plotOffEdges(obj)
            % PLOTOFFEDGES  Plot nodes marked as terminal + offedge
            delete(findall(obj.figureHandle, 'Tag', 'OffEdge'));
            % Get OffEdge and Terminal IDs
            IDs = obj.neuron.getEdgeNodes();
            if isempty(IDs)
                return
            end

            xyz = obj.neuron.id2xyz(IDs);
            h = line(obj.ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                'Marker', '.', 'MarkerSize', 12,...
                'MarkerFaceColor', [0, 0, 0.5],...
                'MarkerEdgeColor', [0, 0, 0.5],...
                'LineStyle', 'none',...
                'Tag', 'OffEdge');
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
            obj.updateStatus('Updating OData...');

            % Update the neuron OData and segmentation
            obj.neuron.update();
            obj.updateStatus('Segmenting...');
            obj.segments = sbfsem.render.Segment(obj.neuron);
            
            % Delete the old plot components
            delete(findall(obj.figureHandle, 'Type', 'surface'));
            delete(findall(obj.figureHandle, 'Type', 'line'));
            
            % Recreate plot components
            obj.updateStatus('Plotting...')
            obj.plotSegments();
            if obj.doSurface
                obj.plotCylinders();
            end
            obj.plotUnfinished();
            obj.plotTerminals();
            obj.plotOffEdges();
            obj.plotSynapses();
            obj.updateStatus();
        end
        
        function onClickMode(obj, src, ~)
            % ONCLICKMODE  Enable or disable data tips

            % Only register if box isn't already selected
            if src.BackgroundColor == [0.7, 0.7, 0.7]
                return;
            end
            
            switch obj.dataCursor.Enable
                case 'on'  % Turn on View mode
                    obj.dataCursor.removeAllDataCursors();
                    set(obj.dataCursor, 'Enable', 'off');
                    set(findobj(obj.figureHandle, 'Tag', 'DCBox'),...
                        'BackgroundColor', 'w');
                    set(findobj(obj.figureHandle, 'Tag', 'ViewBox'),...
                        'BackgroundColor', [0.7, 0.7, 0.7]);
                case 'off'  % Turn on Select mode
                    set(obj.dataCursor, 'Enable', 'on');
                    set(findobj(obj.figureHandle, 'Tag', 'DCBox'),...
                        'BackgroundColor', [0.7, 0.7, 0.7]);
                    set(findobj(obj.figureHandle, 'Tag', 'ViewBox'),...
                        'BackgroundColor', 'w');
            end
        end
        
        function txt = onUpdateCursor(obj, ~, evt)
            % ONUPDATECURSOR  Custom data tip display callback
            pos = get(evt,'Position');
            txt = [];
            switch evt.Target.Tag
                case 'Unfinished'
                    xyz = obj.neuron.id2xyz(obj.neuron.offEdges);
                    ind = find(sum(pos, 2) == sum(xyz, 2));
                    locID = obj.neuron.offEdges(ind); %#ok
                    Z = obj.neuron.nodes{obj.neuron.nodes.ID == locID, 'Z'};
                case 'Terminal'
                    xyz = obj.neuron.id2xyz(obj.neuron.terminals);
                    ind = find(sum(pos, 2) == sum(xyz, 2));
                    locID = obj.neuron.terminals(ind); %#ok
                    Z = obj.neuron.nodes{obj.neuron.nodes.ID == locID, 'Z'};
                case 'Synapse'
                    T = obj.neuron.getSynapseNodes();
                    xyz = T.XYZum;
                    ind = find(sum(pos,2) == sum(xyz, 2));
                    locID = T{ind(1), 'ID'};
                    Z = T{ind(1), 'Z'};     
                    
                    txt = {['SynapseID: ', num2str(T{ind(1), 'ParentID'})]};
                otherwise
                    [locID, Z] = obj.id2xyz(pos, str2double(evt.Target.Tag));
            end
            txt = cat(2, txt, {['ID: ' num2str(locID)],...
                ['Section: ', num2str(Z)]});
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
            colormap(obj.ax, obj.getColormap(obj.cmap, 256));
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
                    obj.updateStatus('Importing synapses...');
                    obj.neuron.getSynapses();
                    obj.plotSynapses();
                    obj.updateStatus('');
                end
            else
                names = obj.neuron.synapseNames;
                for i = 1:numel(names)
                    set(findall(obj.ax, 'Tag', 'Synapse'), 'Visible', 'off');
                end
            end
        end
        
        function onShowUnfinished(obj, src, ~)
            % ONSHOWUNFINISHED  Toggle unfinished branch markers
            if src.Value == 1
                set(findall(obj.ax, 'Tag', 'Unfinished'), 'Visible', 'on');
            else
                set(findall(obj.ax, 'Tag', 'Unfinished'), 'Visible', 'off');
            end
        end
        
        function onShowTerminals(obj, src, ~)
            % ONSHOWTERMINALS  Toggle terminal branch markers
            if src.Value == 1
                set(findall(obj.ax, 'Tag', 'Terminal'), 'Visible', 'on');
            else
                set(findall(obj.ax, 'Tag', 'Terminal'), 'Visible', 'off');
            end
        end

        function onShowOffEdges(obj, src, ~)
            % ONSHOWOFFEDGES  Toggle edge markers
            if src.Value == 1
                set(findall(obj.ax, 'Tag', 'OffEdge'), 'Visible', 'on');
            else
                set(findall(obj.ax, 'Tag', 'OffEdge'), 'Visible', 'off');
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
        
        function onChangedTab(obj, ~, evt)
            % ONCHANGEDTAB  Don't populate table until necessary
            if strcmp(evt.NewValue.Title, 'Table') && isempty(evt.NewValue.Children)
                obj.createTableTab(evt.NewValue);
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
            
            tabLayout = uitabgroup('Parent', obj.figureHandle,...
                'SelectionChangedFcn', @obj.onChangedTab);
            graphTab = uitab(tabLayout, 'Title', 'Graph');
            
            uitab(tabLayout, 'Title', 'Table', 'Tag', 'TableTab');
            obj.createHelpTab(tabLayout);
            
            % The graph layout consists of a UI column and the plot
            mainLayout = uix.HBoxFlex('Parent', graphTab,...
                'BackgroundColor', 'w');
            uiLayout = uix.VBox('Parent', mainLayout,...
                'BackgroundColor', 'w');
            % Data cursor mode requires parent with pixel property
            % Use Matlab's uipanel between axes and HBoxFlex
            hp = uipanel('Parent', mainLayout,...
                'BackgroundColor', 'w');
            obj.ax = axes('Parent', hp);
       
            % Create the user interface panel
            uicontrol(uiLayout, 'Style', 'text', 'String', obj.source);
            modeLayout = uix.VBox('Parent', uiLayout,...
                'BackgroundColor', 'w');
            LayoutManager.verticalBoxWithLabel(modeLayout, 'Mode:',...
                'Style', 'Push',...
                'String', 'View',...
                'Tag', 'ViewBox',...
                'BackgroundColor', [0.7, 0.7, 0.7],...
                'TooltipString', 'Rotate zoom and pan view',...
                'Callback', @obj.onClickMode);
            uicontrol(modeLayout,...
                'Style', 'push',...
                'String', 'Data Cursor',...
                'Tag', 'DCBox',...
                'Tooltip', 'Select individual nodes',...
                'Callback', @obj.onClickMode);
            set(modeLayout, 'Heights', [-2, -1]);
            uix.Empty('Parent', uiLayout);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show synapses',...
                'Value', 0,...
                'Tag', 'ShowSynapses',...
                'TooltipString', 'Show synapse annotations',...
                'Callback', @obj.onShowSynapses);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show surface',...
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
                'String', 'Show unfinished',...
                'Value', 0,...
                'Tag', 'ShowUnfinished',...
                'TooltipString', 'Show nodes marked as unfinished',...
                'Callback', @obj.onShowUnfinished);
            uicontrol(uiLayout,...
                'Style', 'checkbox',...
                'String', 'Show terminals',...
                'Value', 0,...
                'Tag', 'ShowTerminals',...
                'TooltipString', 'Show nodes marked as terminals',...
                'Callback', @obj.onShowTerminals);
            uix.Empty('Parent', uiLayout);
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
                'TooltipString', 'Update to load most recent annotations',...
                'Callback', @obj.onUpdateNeuron);
            uicontrol(uiLayout,...
                'Style', 'text',...
                'String', '',...
                'FontAngle', 'italic',...
                'Tag', 'Status');
            obj.updateStatus('Building...');
            
            obj.createPlot();
            
            set(uiLayout, 'Heights',...
                [-0.5, -1.2, -0.3, -0.5, -0.5, -0.5, -0.5, -0.5, -0.3, -1, -1, -0.8, -0.5]);
        
            set(mainLayout, 'Widths', [-1 -3.5]);

            obj.updateStatus();
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
            obj.plotUnfinished();
            obj.plotTerminals();
            obj.plotOffEdges();
            obj.plotSynapses();
            
            axis(obj.ax, 'equal', 'tight');
            view(obj.ax, 3);
            grid(obj.ax, 'on');
        end
        
        function createTableTab(obj, tabHandle)
            % CREATETABLE  Initialize annotation table

            tablePanel = uipanel('Parent', tabHandle);

            pos = get(obj.figureHandle, 'Position');
            locTable = uitable('Parent', tablePanel,...
                'Data', table2cell(obj.neuron.nodes(:, {'ID', 'ParentID',...
                'VolumeX', 'VolumeY', 'Z', 'Radius', 'OffEdge', 'Terminal'})),...
                'ColumnName', {'ID', 'ParentID', 'X', 'Y', 'Z',...
                'Radius', 'OffEdge', 'Terminal'});
            set(locTable, 'Position', [obj.MARGIN, obj.MARGIN, ...
                pos(3)-obj.MARGIN*2, pos(4)-obj.MARGIN*2]);
        end

        function createHelpTab(obj, parentHandle)
            helpTab = uitab(parentHandle, 'Title', 'Help');

            helpLayout = uix.VBox('Parent', helpTab,...
                'BackgroundColor', 'w');
            uicontrol('Parent', helpLayout,...
                'Style', 'text',...
                'String', obj.getInstructions());
            uix.Empty('Parent', helpLayout);
            set(helpLayout, 'Heights', [-1 -0.1]);
        end
    end
    
    methods (Static, Access = protected)
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
                case 'parula'
                    cmap = parula(N);
                case 'winter'
                    cmap = winter(N);
                case 'hsv'
                    cmap = hsv(N);
                case 'viridis'
                    cmap = viridis(N);
                case 'cubicl'
                    cmap = pmkmp(N, 'CubicL');
                case 'haxby'
                    cmap = haxby(N);
                case 'redblue'
                    cmap = lbmap(N, 'RedBlue');
            end
        end
    end
end
