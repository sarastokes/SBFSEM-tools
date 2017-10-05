classdef NeuronApp < handle
    % Neuron class UI - work in progress
    
    properties (SetAccess = private)
        handles
        data
        neuron
        somaDist
    end
    properties (Access = private)
        standAlone
    end
    
    properties (Hidden, Transient)
        azel = [0 90]  % rotation of 3d plot
    end
    
    %% Constructor
    methods
        function obj = NeuronApp(Neuron)
            % CONSTRUCTOR  NeuronApp
            
            if ~isa(Neuron, 'Neuron')
                error('Input a Neuron object');
            end
            obj.neuron = Neuron;
            if ~isempty(which('populateRenders'))
                obj.standAlone = false;
            else
                obj.standAlone = true;
                fprintf('Running without sbfsem-tools, no 3d render or network support\n');
            end
            createUI(obj);
        end % constructor
    end % methods
    
    %% UI Setup methods
    methods (Access = private)
        function createUI(obj)
            fh = figure('Name', sprintf('Cell %u', obj.neuron.cellData.cellNum),...
                'Color', 'w',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10.5,...
                'DefaultUicontrolBackgroundColor', 'w',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'NumberTitle', 'off');
            
            pos = fh.Position;
            pos(2) = pos(1) - (pos(3) * 1.4);
            pos(3) = pos(3) * 1.4;
            pos(4) = pos(4) * 1.25;
            fh.Position = pos;
            
            obj.handles = struct();
            obj.handles.fh = fh;
            
            % create UI panels
            createUI_main(obj);
            createUI_cellData(obj);
            createUI_plots(obj);
            populateGraphs(obj);
            createUI_network(obj);
            createUI_blender(obj);
            set([findobj(obj.handles.fh, 'Type', 'uix.Box'),...
                findobj(obj.handles.fh, 'Type', 'uix.Panel')],...
                'BackgroundColor', 'w');
            % setup some final callbacks
            set(obj.handles.layouts.tab,...
                'SelectionChangedFcn', @obj.changeTab);
            set(obj.handles.tabs.hist,...
                'SelectionChangedFcn', @obj.changeHistogram);
        end % createUI
        
        function createUI_main(obj)
            mh.file = uimenu('Parent', obj.handles.fh,...
                'Label', 'File');
            uimenu('Parent', mh.file,...
                'Label', 'Save cell',...
                'Callback', @obj.saveNeuron);
            % mh.analysis = uimenu('Parent', obj.handles.fh,...
            %     'Label', 'Analysis');
            mh.reports = uimenu('Parent', obj.handles.fh,...
                'Label', 'Reports');
            uimenu('Parent', mh.reports,...
                'Label', 'Synapse Overview',...
                'Callback', @obj.synapseOverview);
            uimenu('Parent', mh.reports,...
                'Label', 'Unknown synapses',...
                'Callback', @obj.reportUnknown);
            mh.export = uimenu('Parent', obj.handles.fh,...
                'Label', 'Export');
            uimenu('Parent', mh.export,...
                'Label', 'Open figure outside UI',...
                'Callback', @obj.exportFigure);
            uimenu('Parent', mh.export,...
                'Label', 'Export network',...
                'Callback', @obj.exportNetwork);
            uimenu('Parent', mh.export,...
                'Label', 'Export neuron',...
                'Callback', @obj.exportNeuron);
            
            obj.handles.layouts.main = uix.HBoxFlex('Parent', obj.handles.fh,...
                'Spacing', 5, 'BackgroundColor', 'w');
            
            obj.handles.layouts.tab = uix.TabPanel('Parent', obj.handles.layouts.main,...
                'Padding', 5,...
                'FontName', get(obj.handles.fh, 'DefaultUicontrolFontName'),...
                'FontSize', get(obj.handles.fh, 'DefaultUicontrolFontSize'),...
                'BackgroundColor', 'w');
            
            tabs.cellInfo = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5, 'BackgroundColor', 'w');
            tabs.plot = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5, 'BackgroundColor', 'w');
            obj.handles.ax.d3plot = axes('Parent', tabs.plot);
            axis(obj.handles.ax.d3plot, 'equal');
            tabTab = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5, 'BackgroundColor', 'w');
            
            % histogram tabs and sub-tabs
            tabs.hist = uix.TabPanel('Parent', tabTab,...
                'Padding', 5,...
                'FontName', get(obj.handles.fh, 'DefaultUicontrolFontName'),...
                'FontSize', get(obj.handles.fh, 'DefaultUicontrolFontSize'),...
                'BackgroundColor', 'w');
            tabs.soma = uix.Panel('Parent', tabs.hist);
            tabs.z = uix.Panel('Parent', tabs.hist);
            obj.handles.ax.soma = axes('Parent', tabs.soma);
            obj.handles.ax.z = axes('Parent', tabs.z,...
                'YDir', 'reverse');
            tabs.hist.TabTitles = {'Soma', 'Z-axis'};
            tabs.hist.Selection = 1;
            
            tabs.contacts = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5, 'BackgroundColor', 'w');
            tabs.render = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5, 'BackgroundColor', 'w');
            
            obj.handles.layouts.tab.TabTitles = {'Cell Info', '3D plot',...
                'Histograms', 'Network', 'Renders'};
            obj.handles.layouts.tab.Selection = 1;
            
            % add tabs to handles structure
            obj.handles.tabs = tabs;
            
            obj.handles.layouts.ui = uix.VBox('Parent', obj.handles.layouts.main,...
                'Spacing', 1, 'Padding', 5,...
                'BackgroundColor', 'w');
            
            % get the synapse legend colors
            sc = obj.getSynapseColors();
            % throw out cell body and syn multi nodes
            rows = ~strcmp(obj.neuron.dataTable.LocalName, 'cell') ...
                & obj.neuron.dataTable.Unique == 1;
            % make a new table with only unique synapses
            synTable = obj.neuron.dataTable(rows, :);
            % group by LocalName
            [G, names] = findgroups(synTable.LocalName);
            % how many synapse types
            numTypes = numel(names);
            % how many of each type
            numSyn = splitapply(@numel, synTable.LocalName, G);
            % make the table
            tableData = cell(numTypes, 5);
            
            % fill the table
            for ii = 1:numTypes
                % display checkbox
                tableData{ii,1} = false;
                % local name
                tableData{ii,2} = names{ii};
                % unique count
                tableData{ii,3} = numSyn(ii);
                % legend color
                c = obj.rgb2hex_local(sc(names{ii}));
                tableData{ii,4} = obj.setTableCellColor(c, ' ');
                % number of histogram bins (set later)
                tableData{ii,5} = '-';
            end
            
            % create the synapse table
            obj.handles.synTable = uitable('Parent', obj.handles.layouts.ui);
            set(obj.handles.synTable, 'Data', tableData,...
                'ColumnName', {'Plot', 'Synapse', 'N', ' ', 'Bins'},...
                'ColumnEditable', [true false false false true],...
                'ColumnWidth', {35, 100, 40, 25, 30},...
                'RowName', [],...
                'FontName', get(obj.handles.fh, 'DefaultUiControlFontName'),...
                'FontSize', get(obj.handles.fh, 'DefaultUiControlFontSize'),...
                'CellEditCallback', @obj.onEdit_synTable);
        end % createUI_main
        
        function createUI_cellData(obj)
            infoLayout = uix.Panel('Parent', obj.handles.tabs.cellInfo,...
                'Padding', 5, 'BackgroundColor', 'w');
            infoGrid = uix.Grid('Parent', infoLayout,...
                'Padding', 5, 'Spacing', 5,...
                'BackgroundColor', 'w');
            
            % left side
            basicLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Cell number:');
            obj.handles.ed.cellNum = uicontrol(basicLayout,...
                'Style', 'edit', 'String', num2str(obj.neuron.cellData.cellNum));
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Annotator:');
            obj.handles.ed.annotator = uicontrol(basicLayout,...
                'Style', 'edit', 'String', '');
            
            cellTypeLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', cellTypeLayout,...
                'Style', 'text', 'String', 'Cell Type:');
            obj.handles.lst.cellType = uicontrol(cellTypeLayout,...
                'Style', 'list',...
                'String', {'unknown', 'ganglion cell', 'bipolar cell',...
                'horizontal cell', 'amacrine cell',...
                'photoreceptor', 'interplexiform cell'});
            set(cellTypeLayout, 'Heights', [-1 -3]);
            
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'PR inputs:')
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Strata:');
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Polarity:');
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Notes:');
            obj.handles.tx.cellData = uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'No cell data detected');
            
            % right side
            sourceLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', sourceLayout,...
                'Style', 'text', 'String', 'Source');
            obj.handles.lst.source = uicontrol(sourceLayout,...
                'Style', 'list', 'String', {'temporal', 'inferior', 'rc1'});
            set(sourceLayout, 'Heights', [-1 -2]);
            subTypeLayout = uix.VBox('Parent', infoGrid);
            obj.handles.pb.subtype = uicontrol(subTypeLayout,...
                'Style', 'push', 'String', 'Get subtypes:',...
                'Callback', @obj.findSubtypes);
            obj.handles.lst.subtype = uicontrol(subTypeLayout,...
                'Style', 'list');
            set(subTypeLayout, 'Heights', [-1 -3]);
            
            coneLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.lmcone = uicontrol(coneLayout,...
                'Style', 'checkbox',...
                'String', 'L/M-cone');
            obj.handles.cb.scone = uicontrol(coneLayout,...
                'Style', 'checkbox',...
                'String', 'S-cone');
            obj.handles.cb.rod = uicontrol(coneLayout,...
                'Style', 'checkbox', 'String', 'Rod');
            
            strataLayout = uix.HBox('Parent', infoGrid);
            for ii = 1:5
                strata = sprintf('s%u', ii);
                obj.handles.cb.(strata) = uicontrol(strataLayout,...
                    'Style', 'checkbox', 'String', strata);
            end
            polarityLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.onPol = uicontrol(polarityLayout,...
                'Style', 'checkbox', 'String', 'ON');
            obj.handles.cb.offPol = uicontrol(polarityLayout,...
                'Style', 'checkbox', 'String', 'OFF');
            obj.handles.ed.notes = uicontrol(infoGrid,...
                'Style', 'edit', 'String', '');
            obj.handles.pb.addData = uicontrol(infoGrid,...
                'Style', 'push', 'String', 'Add cell data',...
                'Callback', @obj.addCellData);
            
            set(infoGrid, 'Widths', [-1 -1],... 
                'Heights',[-2 -3 -1 -1 -1 -1 -1]);

            % check for cell info
            if obj.neuron.cellData.flag
                titlestr = obj.loadCellData();
                if ~isempty(titlestr)
                    set(obj.handles.fh, 'Name', titlestr);
                end
            end
            
            if isempty(obj.neuron.cellData.cellType)
                set(obj.handles.lst.cellType, 'Value', 1);
                set(obj.handles.lst.subtype, 'Enable', 'off',...
                    'String', {'Pick', 'cell type', 'first'});
            end
        end
        
        function createUI_plots(obj)
            % CREATEUI_PLOTS  Setup the handles for 3d plot and histograms
            obj.handles.layouts.clip = uix.HBox('Parent', obj.handles.layouts.ui);
            obj.handles.tx.clip = uicontrol(obj.handles.layouts.clip,...
                'Style', 'Text',...
                'String', 'Clip view around soma:');
            obj.handles.cb.aboveSoma = uicontrol(obj.handles.layouts.clip,...
                'Style', 'checkbox',...
                'String', 'Above',...
                'Callback', @obj.clipBySoma);
            obj.handles.cb.belowSoma = uicontrol(obj.handles.layouts.clip,...
                'Style', 'checkbox',...
                'String', 'Below',...
                'Callback', @obj.clipBySoma);
            set(obj.handles.layouts.clip,...
                'Widths', [-1.5 -1 -1], 'Visible', 'off');
            
            obj.handles.layouts.skel = uix.HBox('Parent', obj.handles.layouts.ui);
            obj.handles.cb.addSkeleton = uicontrol('Parent', obj.handles.layouts.skel,...
                'Style', 'checkbox',...
                'String', 'Add dendrite plot',...
                'Callback', @obj.addSkeleton,...
                'Visible', 'off');
            obj.handles.pb.skelBack = uicontrol(obj.handles.layouts.skel,...
                'Style', 'push', 'String', '<-', 'Visible', 'off');
            obj.handles.tx.skelBins = uicontrol(obj.handles.layouts.skel,...
                'Style', 'text', 'Visible', 'off');
            obj.handles.pb.skelFwd = uicontrol(obj.handles.layouts.skel,...
                'Style', 'push', 'String', '->', 'Visible', 'off');
            set([obj.handles.pb.skelFwd, obj.handles.pb.skelBack],...
                'Callback', @obj.deltaSkeleton);
            set(obj.handles.layouts.skel,... 
                'Widths', [-2 -0.5 -0.5 -0.5],...
                'BackgroundColor', 'w');
            
            obj.handles.cb.addSoma = uicontrol(obj.handles.layouts.ui,...
                'Style', 'checkbox',...
                'String', 'Add soma',...
                'Value', 1, 'Visible', 'off',...
                'Callback', @obj.addSoma);
            
            obj.handles.pb.findConnectivity = uicontrol(obj.handles.layouts.ui,...
                'Style', 'pushbutton',...
                'String', 'Load connectivity',...
                'Visible', 'off',...
                'Callback', @obj.loadNetwork);
            
            obj.handles.cb.limitDegrees = uicontrol(obj.handles.layouts.ui,...
                'Style', 'checkbox',...
                'String', 'Limit to 1 degree',...
                'Visible', 'off',...
                'Callback', @obj.limitDegrees);
            
            obj.handles.layouts.azels = uix.HBox('Parent', obj.handles.layouts.ui);
            azimuthLayout = uix.VBox('Parent', obj.handles.layouts.azels);
            elevationLayout = uix.VBox('Parent', obj.handles.layouts.azels);
            
            % continuously updating sliders for 3d graph control
            obj.handles.tx.az = uicontrol(azimuthLayout,...
                'Style', 'text',...
                'String', 'Azimuth: ');
            obj.handles.sl.azimuth = uicontrol(azimuthLayout,...
                'Style', 'slider',...
                'Min', 0, 'Max', 360,...
                'SliderStep', [0.0417 0.125],...
                'Value', obj.azel(1));
            obj.handles.slj.azimuth = findjobj(obj.handles.sl.azimuth);
            set(obj.handles.slj.azimuth,...
                'AdjustmentValueChangedCallback', @obj.setAzimuth);
            
            obj.handles.tx.el = uicontrol(elevationLayout,...
                'Style', 'text',...
                'String', 'Elevation: ');
            obj.handles.sl.elevation = uicontrol(elevationLayout,...
                'Style', 'slider',...
                'Min', 0, 'Max', 360,...
                'SliderStep', [0.0417 0.125],...
                'Value', obj.azel(2));
            obj.handles.slj.elevation = findjobj(obj.handles.sl.elevation);
            set(obj.handles.slj.elevation,...
                'AdjustmentValueChangedCallback', @obj.setElevation);
            
            set(obj.handles.layouts.main, 'Widths', [-1.5 -1],...
                'BackgroundColor', 'w');
            % set(viewLayout, 'Widths', [-1 -1]);
            set(obj.handles.layouts.ui, 'Heights', [-4 -1 -1 -1 -1 -1 -1]);
            
            set(obj.handles.layouts.azels, 'Visible', 'off',...
                'BackgroundColor', 'w');
        end
        
        function createUI_network(obj)
            obj.handles.ax.adj = axes('Parent', obj.handles.tabs.contacts);
            if ~isempty(obj.neuron.conData)
                % this is an asymmetric graph
                adjMat = weightedAdjacencyMatrix(obj.neuron.conData.contacts,...
                    obj.neuron.conData.edgeTable.Weight);
                pcolor(obj.handles.ax.adj, adjMat);
                axis(obj.handles.ax.adj, 'square');
                set(obj.handles.ax.adj,...
                    'XTickLabelRotation', 90,...
                    'XTickLabel', obj.neuron.conData.nodeTable.CellID,...
                    'XTick', 1:length(adjMat),...
                    'YTickLabel', obj.neuron.conData.nodeTable.CellID,...
                    'YTick', 1:length(adjMat),...
                    'FontSize', 7);
            end
        end % createUI_network
        
        function createUI_blender(obj)
            % this tab finds and displays renders of the neuron
            renderLayout = uix.VBox('Parent', obj.handles.tabs.render,...
                'Spacing', 5, 'BackgroundColor', 'w');
            obj.handles.ax.render = axes('Parent', renderLayout);
            renderUiLayout = uix.HBox('Parent', renderLayout,...
                'BackgroundColor', 'w');
            obj.handles.lst.renders = uicontrol(renderUiLayout,...
                'Style', 'listbox');
            obj.handles.pb.showRender = uicontrol(renderUiLayout,...
                'Style', 'push',...
                'String', '<html>show<br/>render',...
                'Callback', @obj.showRender);
            set(renderLayout, 'Heights', [-4 -1]);
            set(renderUiLayout, 'Widths', [-5 -1]);
            % populateRenders searches for 'c#' matches in blender dir
            if ~obj.standAlone
                renderList = populateRenders(obj.neuron.cellData.cellNum);
            else
                renderList = '';
            end
            set(obj.handles.lst.renders, 'String', renderList);
        end % createUI_blender
        
        function populateGraphs(obj)
            % POPULATEGRAPHS  Creates 3d plot and histogram data
            sc = obj.getSynapseColors();
            T = obj.neuron.dataTable;
            
            somaXYZ = obj.neuron.getSomaXYZ();
            
            % throw out the cell body and multiple slide synapses
            rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
            % make a new table with only unique synapses
            synTable = T(rows, :);
            % group by LocalName
            [~, names] = findgroups(synTable.LocalName);
            % how many synapse types
            numSyn = numel(names);
            
            obj.handles.numBins = zeros(2, numSyn+1);
            obj.somaDist = cell(numSyn, 1);
            
            % create the plots by synapse type
            for ii = 1:numSyn
                % synapse 3d plot
                xyz = obj.neuron.getSynapseXYZ(names{ii});
                obj.handles.lines(ii) = line('Parent', obj.handles.ax.d3plot,...
                    'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
                    'Color', sc(names{ii}), 'Marker', '.',...
                    'MarkerSize', 9, 'LineStyle', 'none',...
                    'Visible', 'off');
                
                % synapse distance histograms
                obj.somaDist{ii,1} = obj.euclid3d(somaXYZ, xyz);
                [counts, bins] = histcounts(obj.somaDist{ii, 1});
                binInc = bins(2) - bins(1);
                cent = bins(1:end-1) + binInc/2;
                obj.handles.somaBins(ii) = line('Parent', obj.handles.ax.soma,...
                    'XData', cent, 'YData', counts,...
                    'Color', sc(names{ii}),...
                    'LineWidth', 2, 'Visible', 'off');
                obj.handles.numBins(1,ii) = length(bins);
                % tableData = get(handles.synTable, 'Data');
                obj.handles.synTable.Data{ii,5} = length(bins);
                
                % z-axis plot
                [counts, binCenters] = obj.getHist(xyz(:,3));
                obj.handles.zBins(ii) = line('Parent', obj.handles.ax.z,...
                    'XData', counts, 'YData', binCenters,...
                    'Color', sc(names{ii}),...
                    'LineWidth', 2);
                set(obj.handles.zBins(ii), 'Visible', 'off');
                obj.handles.numBins(2,ii) = length(binCenters + 1);
            end
            xlabel(obj.handles.ax.z, 'synapse counts');
            
            ylabel(obj.handles.ax.z, 'z-axis (microns)');
            xlabel(obj.handles.ax.soma, 'distance from soma');
            ylabel(obj.handles.ax.soma, 'synapse count');
            
            
            % plot the cell's skeleton
            skelRow = strcmp(T.LocalName, 'cell');
            xyz = table2array(T(skelRow, 'XYZum'));
            obj.handles.skeletonLine = line('Parent', obj.handles.ax.d3plot,...
                'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
                'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
                'LineStyle', 'none', 'Visible', 'off');
            
            % stratification histogram
            [counts, bins] = obj.getHist(xyz(:,3));
            obj.handles.skeletonBins = line('Parent', obj.handles.ax.z,...
                'XData', counts, 'YData', bins,...
                'LineWidth', 2, 'Color', 'k',...
                'Visible', 'off');
            obj.handles.numBins(2, numSyn+1) = length(bins);
            
            % soma dist histogram
            obj.somaDist{numSyn,1} = obj.euclid3d(somaXYZ, xyz);
            [counts, bins] = obj.getHist(obj.somaDist{numSyn, 1});
            obj.handles.radialBins = line('Parent', obj.handles.ax.soma,...
                'XData', bins, 'YData', counts,...
                'LineWidth', 2, 'Color', 'k', 'Visible', 'off');
            
            set(obj.handles.tx.skelBins, 'String', num2str(length(bins)));
            obj.handles.numBins(1, numSyn+1) = length(bins);
            
            % plot the soma - keep it visible
            obj.handles.somaLine = line('Parent', obj.handles.ax.d3plot,...
                'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
                'Marker', '.', 'MarkerSize', 20, 'Color', 'k');
            
            axis(obj.handles.ax.d3plot, 'equal');
            xlabel(obj.handles.ax.d3plot, 'x-axis (microns)');
            ylabel(obj.handles.ax.d3plot, 'y-axis (microns)');
            zlabel(obj.handles.ax.d3plot, 'z-axis (microns)');
        end % populatePlots
    end % methods private
    
    %% UI callbacks
    methods (Access = private)
        % ------------------------------------------------ 3d plot callbacks ------
        function toggleSyn(obj, whichSyn, toggleState)
            % TOGGLESYN  Adds/removes synapse to plot
            set([obj.handles.lines(whichSyn),...
                obj.handles.somaBins(whichSyn),...
                obj.handles.zBins(whichSyn)], 'Visible', toggleState);
        end % toggleSyn
        
        % ----------------------------------------- I/O callbacks ---------
        function saveNeuron(obj, ~, ~)
            % SAVENEURON  Calls neuron's save fcn
            obj.neuron.saveNeuron();
        end
        
        function addCellData(obj, ~, ~)
            % ADDCELLDATA  Add cell info panel changes to cell data
            inputTypes = {'lmcone', 'scone', 'rod'};
            for ii = 1:length(inputTypes)
                obj.neuron.cellData.inputs(ii) = obj.handles.cb.(inputTypes{ii}).Value;
            end
            
            strata = 1:5;
            for ii = 1:length(strata)
                obj.neuron.cellData.strata(1, ii) =...
                    obj.handles.cb.(sprintf('s%u', ii)).Value;
            end
            
            obj.neuron.cellData.flag = true;
            set(obj.handles.tx.cellData, 'String', 'Cell data added!');
        end % addCellData
        
        function titlestr = loadCellData(obj)
            % LOADCELLDATA  Add existing cell data to display
            obj.handles.ed.cellNum.String = num2str(obj.neuron.cellData.cellNum);
            titlestr = obj.handles.ed.cellNum.String;
            obj.handles.ed.annotator.String = obj.neuron.cellData.annotator;
            set(obj.handles.lst.source, 'Value',...
                find(ismember(obj.handles.lst.source.String, lower(obj.neuron.cellData.source))));
            if ~isempty(obj.neuron.cellData.cellType)
                set(obj.handles.lst.cellType, 'Value',...
                    find(ismember(obj.handles.lst.cellType.String, obj.neuron.cellData.cellType)));
                % call subtypes
                if ~strcmp(obj.neuron.cellData.cellType, 'unknown')
                    set(obj.handles.lst.subtype,...
                        'String', obj.findSubtypes(obj.neuron.cellData.cellType),...
                        'Enable', 'on');
                    if ~isempty(obj.neuron.cellData.subType)
                        set(obj.handles.lst.subtype, 'Value',...
                            find(ismember(obj.handles.lst.subtype.String, obj.neuron.cellData.subType)));
                        titlestr = [titlestr ' ' obj.neuron.cellData.subType];
                    end
                end
                titlestr = [titlestr ' ' obj.neuron.cellData.cellType];
            end
            
            
            obj.handles.cb.onPol.Value = obj.neuron.cellData.onoff(1);
            obj.handles.cb.offPol.Value = obj.neuron.cellData.onoff(2);
            
            for ii = 1:5 % number of strata
                obj.handles.cb.(sprintf('s%u', ii)).Value = obj.neuron.cellData.strata(1,ii);
            end
            
            inputTypes = {'lmcone', 'scone', 'rod'};
            for ii = 1:length(inputTypes)
                obj.handles.cb.(inputTypes{ii}).Value = obj.neuron.cellData.inputs(ii);
            end
            
            obj.handles.ed.notes.String = obj.neuron.cellData.notes;
        end
        
        function getSubtypes(obj, ~, ~)
            % GETSUBTYPES  Get subtypes for selected cell type
            cType = obj.handles.lst.cellType.String{obj.handles.lst.cellType.Value};
            if strcmp(cType, 'unknown')
                set(obj.handles.pb.subtype, 'String', 'Pick a type first!');
            else
                set(obj.handles.lst.subtype,...
                    'String', getCellSubtypes(cType),...
                    'Enable', 'on');
            end
        end % getSubtypes
        % ------------------------------------------------ network callbacks ------
        function loadNetwork(obj, ~, ~)
            % LOADNETWORK  Loads network from JSON file
            obj.neuron.addNetwork();
            disp('Note: network file is not saved to neuron');
        end % loadNetwork
        
        function limitDegrees(obj, ~,~)
            % LIMITDEGREES  Change degrees of separation in network matrix
            % TODO: this is totally repetitive, fix at some point
            if get(obj.handles.cb.limitDegrees, 'Value') == 1
                % find only the contacts containing target neuron
                cellNode = find(obj.neuron.conData.nodeTable.CellID == obj.neuron.cellData.cellNum);
                hasNeuron = bsxfun(@eq, cellNode, obj.neuron.conData.contacts);
                ind = find(sum(hasNeuron, 2));
                adjMat = weightedAdjacencyMatrix(obj.neuron.conData.contacts(ind,:),...
                    obj.neuron.conData.edgeTable.Weight(ind,:));
            else
                adjMat = weightedAdjacencyMatrix(obj.neuron.conData.contacts,...
                    obj.neuron.conData.edgeTable.Weight);
            end
            
            cla(obj.handles.ax.adj);
            pcolor(obj.handles.ax.adj, adjMat);
            axis(obj.handles.ax.adj, 'square');
            set(obj.handles.ax.adj,...
                'XTickLabelRotation', 90,...
                'XTickLabel', obj.neuron.conData.nodeTable.CellID,...
                'XTick', 1:length(adjMat),...
                'YTickLabel', obj.neuron.conData.nodeTable.CellID,...
                'YTick', 1:length(adjMat),...
                'FontSize', 7);
            
            if get(obj.handles.cb.limitDegrees, 'Value') == 1
                set(obj.handles.ax.adj,...
                    'XTickLabel', obj.neuron.conData.nodeTable.CellID(ind,:),...
                    'YTickLabel', obj.neuron.conData.nodeTable.CellID(ind,:));
            end
        end % limitDegrees
        
        % ------------------------------------------------ render callbacks -------
        function showRender(obj,~,~)
            % SHOWRENDER  Display the selected image
            imName = obj.handles.lst.renders.String{obj.handles.lst.renders.Value};
            imName = [getFilepaths('render') imName];
            im = imread(imName);
            imshow(im(:,:,1:3), 'Parent', obj.handles.ax.render,...
                'InitialMagnification', 'fit');
        end % showRender
        
        % ------------------------------------------------ 3d plot callbacks ------
        function setAzimuth(obj, ~, ~)
            % SETAZIMUTH  Changes azimuth of 3d plot
            obj.azel(1) = get(obj.handles.sl.azimuth, 'Value');
            view(obj.handles.ax.d3plot, obj.azel);
        end % setAzimuth
        
        function setElevation(obj, ~, ~)
            % SETELEVATION  Changes elevation of 3d plot
            obj.azel(2) = get(obj.handles.sl.elevation, 'Value');
            view(obj.handles.ax.d3plot, obj.azel);
        end % setElevation
        
        function onEdit_synTable(obj, src, eventdata)
            % ONEDIT_SYNTABLE  Switchboard for data table callbacks
            tableData = src.Data;
            tableInd = eventdata.Indices;
            switch tableInd(2)
                case 1
                    tof = tableData(tableInd(1), tableInd(2));
                    if tof{1}
                        obj.toggleSyn(tableInd(1), 'on');
                    else
                        obj.toggleSyn(tableInd(1), 'off');
                    end
                case 5
                    synInd = tableInd(1);
                    nBins = tableData{tableInd(1), tableInd(2)};
                    xyz = obj.neuron.getSynapseXYZ(char(tableData(synInd, 2)));
                    switch obj.handles.tabs.hist.Selection
                        case 1
                            
                            [counts, bins] = obj.getHist(obj.somaDist{synInd}, nBins);
                            set(obj.handles.somaBins(synInd), 'XData', bins, 'YData', counts);
                        case 2
                            [counts, bins] = obj.getHist(xyz(:,3), nBins);
                            set(obj.handles.zBins(synInd), 'XData', counts, 'YData', bins);
                    end
                    obj.handles.numBins(obj.handles.tabs.hist.Selection, synInd) = nBins;
            end
            src.Data = tableData; % update table
        end % onEdit_synTable
        
        function addSkeleton(obj,~,~)
            % ADDSKELETON  Toggles display of neuron skeleton
            if get(obj.handles.cb.addSkeleton, 'Value') == 1
                set([obj.handles.skeletonLine,...
                    obj.handles.skeletonBins,...
                    obj.handles.radialBins], 'Visible', 'on');
                set([obj.handles.pb.skelBack,...
                    obj.handles.pb.skelFwd,...
                    obj.handles.tx.skelBins], 'Visible', 'on');
            else
                set([obj.handles.skeletonLine,...
                    obj.handles.skeletonBins,...
                    obj.handles.radialBins], 'Visible', 'off');
                set([obj.handles.pb.skelBack,...
                    obj.handles.pb.skelFwd,...
                    obj.handles.tx.skelBins], 'Visible', 'off');
            end
        end % addSkeleton
        
        function addSoma(obj,~,~)
            % ADDSOMA  Toggles display of soma node in 3d plot
            if get(obj.handles.cb.addSoma, 'Value') == 1
                set(obj.handles.somaLine, 'Visible', 'on');
            else
                set(obj.handles.somaLine, 'Visible', 'off');
            end
        end % addSoma
        
        function clipBySoma(obj, ~, ~)
            % CLIPBYSOMA  Modifies axes limits around soma
            somaXYZ = obj.neuron.getSomaXYZ(obj.neuron.dataTable, obj.neuron.somaNode);
            % get ZLim
            xyz = obj.dataTable.XYZ;
            zBounds = [min(xyz(:,3)) max(xyz(:,3))];
            
            % reset the axis limit
            obj.handles.ax.d3plot.ZLim = zBounds;
            % modify based on checkboxes
            if obj.handles.cb.aboveSoma.Value == 1
                obj.handles.ax.d3plot.ZLim(1) = somaXYZ(3);
            elseif obj.handles.cb.belowSoma.Value == 1
                obj.handles.ax.d3plot.ZLim(2) = somaXYZ(3);
            end
        end % clipBySoma
        
        % ----------------------------------------------- histogram callbacks -----
        function deltaSkeleton(obj, src, ~)
            % DELTASKELETON  Change bin # for dendrite histogram
            t = obj.handles.tabs.hist.Selection;
            
            nbin = obj.handles.numBins(t, end);
            switch src.String
                case '->'
                    nbin = nbin + 1;
                case '<-'
                    nbin = nbin - 1;
            end
            if nbin == 0
                return;
            end
            if t == 1
                [counts, bins] = obj.getHist(obj.somaDist{end}, nbin);
                set(obj.handles.radialBins, 'XData', bins, 'YData', counts);
            else
                skelRow = strcmp(obj.neuron.dataTable.LocalName, 'cell');
                xyz = table2array(obj.neuron.dataTable(skelRow, 'XYZum'));
                [counts, bins] = obj.getHist(xyz(:,3), nbin+1);
                set(obj.handles.skeletonBins, 'XData', counts, 'YData', bins);
            end
            % update UI
            set(obj.handles.tx.skelBins, 'String', num2str(nbin));
            obj.handles.numBins(t,end) = nbin;
        end % deltaSkeleton
        
        function changeHistogram(obj,~,~)
            % CHANGEHISTOGRAM  Updates bin # display for each histogram
            t = obj.handles.tabs.hist.Selection;
            for ii = 1:length(obj.neuron.synList)
                obj.handles.synTable.Data{ii,5} = obj.handles.numBins(t,ii);
            end
            obj.handles.tx.skelBins.String = num2str(obj.handles.numBins(t,end));
        end % changeHistogram
        % ------------------------------------------ tab navigation callbacks -----
        function changeTab(obj, ~, ~)
            % CHANGETAB  Toggles component visibility
            
            % all component visibility defaults to 'off'
            set([obj.handles.cb.addSoma,...
                obj.handles.pb.findConnectivity,...
                obj.handles.pb.skelBack, obj.handles.pb.skelFwd,...
                obj.handles.tx.skelBins, obj.handles.cb.limitDegrees],...
                'Visible', 'off');
            set([obj.handles.layouts.azels, obj.handles.layouts.clip],...
                'Visible', 'off');
            
            switch obj.handles.layouts.tab.Selection
                case 1 % cell info tab
                case 2 % 3d plot tab
                    set([obj.handles.layouts.azels,...
                        obj.handles.layouts.skel,...
                        obj.handles.cb.addSoma,...
                        obj.handles.cb.addSkeleton],...
                        'Visible', 'on');
                case 3 % histogram tab
                    set(obj.handles.cb.addSkeleton, 'Visible', 'on');
                    if obj.handles.cb.addSkeleton.Value
                        set([obj.handles.pb.skelBack,...
                            obj.handles.pb.skelFwd,...
                            obj.handles.tx.skelBins], 'Visible', 'on');
                    end
                case 4 % network tab
                    set([obj.handles.pb.findConnectivity,...
                        obj.handles.cb.limitDegrees],...
                        'Visible', 'on');
            end
        end % changeTab
        
        
        % ----------------------------------------------- report callbacks -----
        function exportNetwork(obj, ~, ~)
            % EXPORTNETWORK  Export network tables as .csv or .txt
            [dataDir, fileType] = obj.setupSave();
            switch fileType
                case 'Excel'
                    fileName = [dataDir filesep sprintf('c%u_networkEdges.xls',...
                        obj.neuron.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.neuron.conData.edgeTable));
                    fileName = [dataDir filesep sprintf('c%u_networkNodes.xls',...
                        obj.neuron.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.neuron.conData.edgeTable));
                case 'Text'
                    disp(obj.neuron.conData.edgeTable);
                    disp(obj.neuron.conData.nodeTable);
            end
        end % exportNetwork
        
        function exportNeuron(obj, ~, ~)
            % EXPORTNEURON  Exports neuron table as csv or txt
            [dataDir, fileType] = obj.setupSave();
            switch fileType
                case 'Excel'
                    fileName = [dataDir filesep...
                        sprintf('c%u_dataTable.xls', obj.neuron.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.neuron.dataTable));
                case 'Text'
                    disp(obj.neuron.dataTable);
            end
        end % exportNeuron
        
        function exportFigure(obj, ~, ~)
            % EXPORTFIGURE  Open current figure in new window
            switch obj.handles.layouts.tab.Selection
                case 2
                    ax = obj.handles.ax.d3plot;
                case 3
                    if obj.handles.tabs.hist.Selection == 1
                        ax = obj.handles.ax.soma;
                    else
                        ax = obj.handles.ax.z;
                    end
                case 4
                    ax = obj.handles.ax.adj;
                case 5
                    ax = obj.handles.ax.render;
                otherwise
                    warndlg('No graph in current window!');
                    return;
            end
            newAxes = copyobj(ax, figure);
            set(newAxes, 'ActivePositionProperty', 'outerposition',...
                'Units', 'normalized',...
                'OuterPosition', [0 0 1 1],...
                'Position', [0.13 0.11 0.775 0.815],...
                'XColor', 'w', 'YColor', 'w');
            axis(newAxes, 'tight');
            title(newAxes, ['c' num2str(obj.neuron.cellData.cellNum)]);
            % keep only visible components
            lines = findall(newAxes, 'Type', 'line', 'Visible', 'off');
            delete(lines);
        end % exportFigure
        
        function reportUnknown(obj, ~, ~)
            % REPORTUNKNOWN  Return locations of unknown synapses
            r = strcmp(obj.neuron.dataTable, 'unknown') == 1;
            newTable = obj.neuron.dataTable(r, :);
            
            fprintf('found %u unknown synapses\n', size(newTable, 1));
            selection = questdlg(...
                sprintf('Save %u unknown synapses', size(newTable, 1)),...
                'Save Dialog',...
                'Yes', 'No', 'Yes');
            switch selection
                case 'Yes'
                    fid = fopen(sprintf('c%u_unknown.txt',...
                        obj.neuron.cellData.cellNum));
                    fprintf(fid, '%u \n', table2array(newTable));
                    fclose(fid);
                    fprintf('%u unknown synapses saved\n', size(newTable, 1));
                case 'No'
                    return;
            end
        end % reportUnknown
        
        function synapseOverview(obj, ~, ~)
            % SYNAPSEOVERVIEW  Save the different synapse types
            selection = questdlg('Save synapse overview?',...
                'Save dialog',...
                'Yes', 'No', 'Yes');
            switch selection
                case 'Yes'
                    r = ~strcmp(obj.neuron.dataTable.LocalName, 'cell') & ...
                        obj.neuron.dataTable.Unique == 1;
                    newTable = obj.neuron.dataTable(r, :);
                    [G, names] = findgroups(newTable.LocalName);
                    numUnique = splitapply(@numel, newTable.localName, G);
                    
                    fid = fopen(sprintf('c%u_overview.txt', obj.neuron.cellData.cellNum));
                    fprintf(fid, 'c%u Synases: \n', obj.neuron.cellData.cellNum);
                    for ii = 1:length(names)
                        fprintf(fid, '%u - %s\n', numUnique(ii), names{ii});
                    end
                    fprintf(fid, '\ngenerated on %s', datestr(now));
                    fclose(fid);
                case 'No'
                    return;
            end
        end % synapseOverview

        function [dataDir, fileType] = setupSave(obj)
            % SETUPSAVE  Dialog used by reports to set save options
            if ~obj.standAlone && ~isempty(getFilepaths('data'))
                cd(getFilepaths('data'));
            end
            dataDir = uigetdir(cd, 'Pick a directory');
            if isempty(dataDir)
                return;
            end
            fileType = questdlg('File format?',...
                'Save dialog',...
                'Excel', 'Text', 'Excel');
        end % setupSave
    end % methods private
    
    methods (Static)
        function distFromSoma = euclid3d(somaXYZ, targetXYZ)
            % EUCLID3D  Fast fcn for distance between 2 points
            % TODO: is this actually the most efficient?
            
            somaXYZ = repmat(somaXYZ, [size(targetXYZ,1) 1]);
            
            x = bsxfun(@minus, somaXYZ(:,1), targetXYZ(:,1));
            y = bsxfun(@minus, somaXYZ(:,2), targetXYZ(:,2));
            z = bsxfun(@minus, somaXYZ(:,3), targetXYZ(:,3));
            
            distFromSoma = sqrt(x.^2 + y.^2 + z.^2);
        end
        
        function [counts, binCenters] = getHist(x, nBins)
            % GETHIST  Get bin centers from histcounts
            if nargin < 2
                [counts, bins] = histcounts(x);
            else
                [counts, bins] = histcounts(x, nBins);
            end
            binInc = bins(2) - bins(1);
            binCenters = bins(1:end-1) + binInc/2;
        end % getHist
    end % static methods
    
    methods (Static) % UI setup methods
        function x = findSubtypes(cellType)
            % GETSUBTYPES  Get subtypes of a cell type
            
            switch lower(cellType)
                case {'ganglion cell', 'gc'}
                    x = {'unknown','midget', 'parasol', 'small bistratified',...
                        'large bistratified', 'smooth', 'melanopsin', 'broad throny'};
                case {'amacrine cell', 'ac'}
                    x = {'unknown', 'wiry', 'semilunar',...
                        'aii', 'a17', 'a1', 'a8', 'a3', 'a5'...
                        'starburst', 'dopaminergic', 'on-off lateral'};
                case {'horizontal cell', 'hc'}
                    x = {'unknown', 'h1', 'h2', 'axon1', 'axon2'};
                case {'bipolar cell', 'bc'}
                    x = {'unknown', 'midget', 'blue', 'rod', 'giant',...
                        'db1', 'db2', 'db3a', 'db3b', 'db4', 'db5', 'db6'};
                case {'photoreceptor', 'pr'}
                    x = {'s', 'lm', 'rod', 'l', 'm'};
                case {'interplexiform cell', 'ipc'}
                    x = {'unknown'};
            end
        end % getSubtypes
        
        function sc = getSynapseColors()
            % GETSYNAPSECOLORS  Default colors for each synapse type
            sc = containers.Map;
            sc('gap junction') = [0.584313725490196 0.815686274509804 0.988235294117647];
            sc('bip conv pre') = [0.0235294117647059 0.32156862745098 1];
            sc('bip conv post') = [0.0156862745098039 0.847058823529412 0.698039215686274];
            sc('ribbon pre') = [0.0823529411764706 0.690196078431373 0.101960784313725];
            sc('ribbon post') = [0.250980392156863 0.63921568627451 0.407843137254902];
            sc('conv pre') = [1 0.27843137254902 0.298039215686275];
            sc('conv post') = [0.992156862745098 0.666666666666667 0.282352941176471];
            sc('touch') = [0.0745098039215686 0.917647058823529 0.788235294117647];
            sc('adherens') = [0.0235294117647059 0.603921568627451 0.952941176470588];
            sc('unknown') = [0.5 0.5 0.5];
            % Inferior monkey project            
            sc('desmosome') = [0.0235294117647059 0.603921568627451 0.952941176470588];
            sc('desmosome post') = [0.0235294117647059 0.603921568627451 0.952941176470588];
            sc('desmosome pre') = [0.0235294117647059 0.603921568627451 0.952941176470588];
            sc('triad basal') =[1 0.27843137254902 0.298039215686275];
            sc('nontriad basal') = [0.517647058823529 0 0];
            sc('marginal basal') = [0.517647058823529 0 0];
            sc('hc bc pre') = [0.780392156862745 0.376470588235294 1];
            sc('hc bc post') = [0.780392156862745 0.376470588235294 1];
            sc('gaba fwd') = [0.780392156862745 0.376470588235294 1];
            % RC1
            sc('endocytosis') = [0.564705882352941 0.894117647058824 0.756862745098039];
            sc('postsynapse') = [0.992156862745098 0.666666666666667 0.282352941176471];
            sc('conventional') = [1 0.27843137254902 0.298039215686275];
 

        end
        
        function hexColor = rgb2hex_local(rgbColor)
            % RGB2HEX  Streamlined version of rgb2hex by Chad A. Greene
            if max(rgbColor(:))<=1
                rgbColor = round(rgbColor*255);
            else
                rgbColor = round(rgbColor);
            end
            
            hexColor(:,2:7) = reshape(sprintf('%02X',rgbColor.'),6,[]).';
            hexColor(:,1) = '#';
        end
        
        function x = setTableCellColor(hexColor, txt)
            % SETTABLECELLCOLOR  Use HTML to create legend cells
            x = ['<html><table border=0 width=200 bgcolor=',...
                hexColor, '><TR><TD>', txt, '</TD></TR> </table></html>'];
        end % setTableCellColor
    end % methods static
end % classdef
