classdef Neuron < handle
    % Analysis and graphs based only on nodes, without edges
    % 14Jun2017 - SSP - created
    % 01Aug2017 - SSP - switched createUi to separate NeuronApp class
    
    properties
        cellData
        saveDir
    end
    
    properties (SetAccess = private, GetAccess = public)
        % these are properties parsed from tulip data
        skeleton % just the "cell" nodes
        dataTable % The properties included are: LocationInViking,
        % LocationID, ParentID, StructureType, Tags, ViewSize, OffEdge and
        % Terminal. See parseNodes.m for more details
        
        synData % this contains data about each synapse type in the cell
        parseDate % date .tlp or .tlpx file created
        analysisDate % date run thru NeuronNodes
        
        connectivityDate % date added connectivity
        conData % connectivity data
        
        synList
        somaNode % largest "cell" node
    end
    
    properties (Access = private)
        nodeList % all nodes
        tulipData
    end
    
    properties (Hidden, Transient)
        fh % UI figure
        handles % all components of UI figure
        somaDist % euclidean distance of each node from soma
        azel = [0 90]% current azimuth + elevation view
    end
    
    methods
        function obj = Neuron(jsonData, cellNum, source, varargin)
            
            % create the cellData structure
            obj.cellData = struct();
            % get the cell number if not provided
            if nargin < 2
                answer = inputdlg('Input the cell number:',...
                    'Cell number dialog box', 1);
                cellNum = answer{1};
                obj.cellData.cellNum = str2double(cellNum);
            else
                obj.cellData.cellNum = cellNum;
            end
            
            % get the source if not provided
            if nargin >= 3
                switch lower(source)
                    case {'temporal', 't'}
                        source = 'temporal';
                    case {'inferior', 'i'}
                        source = 'inferior';
                    case {'rc1', 'r'}
                        source = 'rc1';
                    otherwise
                        warndlg('valid source names: (temporal, t), (inferior, i), (rc1, r)');
                        source = obj.getSource();
                end
            else
                source = obj.getSource();
            end
            obj.cellData.source = source;
            
            % parse additional inputs
            ip = inputParser();
            ip.addParameter('ct', [],  @(x) any(validatestring(upper(x), getCellTypes(1))));
            ip.addParameter('st', [], @ischar);
            ip.addParameter('pol', [], @(x) ischar(x) || isnumeric(x));
            ip.addParameter('prs', [], @isnumeric);
            ip.addParameter('strata', [], @isnumeric);
            ip.addParameter('ann', [], @ischar);
            ip.parse(varargin{:});
            
            % set the cellType
            obj.cellData.cellType = [];
            if ~isempty(ip.Results.ct)
                % first check abbreviated types
                % {'--', 'GC', 'BC', 'HC', 'AC','PR', 'IPC'};
                x = getCellTypes;
                ind = find(not(cellfun('isempty',...
                    strfind(getCellTypes(1), upper(ip.Results.ct)))));
                obj.cellData.cellType = [x{ind}]; %#ok<FNDSB>
                fprintf('set cell type to %s\n', obj.cellData.cellType);
            end
            
            % set the subtype
            obj.cellData.subType = [];
            if ~isempty(obj.cellData.cellType) && ~isempty(ip.Results.st)
                x = getCellSubtypes(obj.cellData.cellType);
                if any(ismember(x, lower(ip.Results.st)));
                    ind = find(not(cellfun('isempty',...
                        strfind(x, lower(ip.Results.st)))));
                    obj.cellData.subType = [x{ind}];  %#ok<FNDSB>
                    fprintf('set subtype to %s\n', obj.cellData.subType);
                else
                    fprintf('SubType %s not found\n', ip.Results.st);
                end
            end
            
            % set the polarity
            obj.cellData.onoff = [0 0];
            if ~isempty(ip.Results.pol)
                pol = ip.Results.pol;
                if isvector(pol) && numel(pol) == 2
                    obj.cellData.onoff = pol;
                elseif ischar(pol)
                    switch lower(pol)
                        case 'on'
                            obj.cellData.onoff(1) = 1;
                        case 'off'
                            obj.cellData.onoff(2) = 1;
                        case 'onoff'
                            obj.cellData.onoff = [1 1];
                    end
                end
            end
            
            % set the cone inputs
            obj.cellData.inputs = zeros(1,3);
            if ~isempty(ip.Results.prs)
                prs = ip.Results.prs;
                if numel(prs) == 1
                    obj.cellData.inputs(prs) = 1;
                elseif numel(prs) == 3
                    obj.cellData.inputs = prs;
                end
            end
            
            % set the strata
            obj.cellData.strata = zeros(1,5);
            if ~isempty(ip.Results.strata)
                strat = ip.Results.strata;
                if numel(strat) == 5 && max(strat) == 1
                    obj.cellData.strata = strat;
                elseif max(strat) <= 5
                    obj.cellData.strata(strat) = 1;
                end
            end
            
            % set the annotator initials
            obj.cellData.annotator = ip.Results.ann;

            % trigger loadCellData in NeuronApp
            if nargin > 3
                obj.cellData.flag = true;
            else
                obj.cellData.flag = false;
            end
            
            obj.cellData.notes = [];
            
            % parse the neuron
            obj.json2Neuron(jsonData, source);
            
            rows = ~strcmp(obj.dataTable.LocalName, 'cell') & obj.dataTable.Unique == 1;
            synTable = obj.dataTable(rows,:);
            [~, obj.synList] = findgroups(synTable.LocalName);
            
        end % constructor
        
        %% ------------------------------------------------ setup functions -----
        function updateData(obj, jsonData)
            obj.json2Neuron(jsonData, obj.cellData.source);
            obj.analysisDate = datestr(now);
            fprintf('updated underlying data\n');
        end % update data
        
        function json2Neuron(obj, jsonData, source)
            % detect input type
            if ischar(jsonData) && strcmp(jsonData(end-3:end), 'json')
                fprintf('parsing with loadjson.m...');
                jsonData = loadjson(jsonData);
                fprintf('parsed\n');
                jsonData = parseNeuron(jsonData, source);
                obj.dataTable = jsonData.dataTable;
            elseif isstruct(jsonData) && isfield(jsonData, 'version')
                jsonData = parseNeuron(jsonData, source);
            elseif isstruct(jsonData) && isfield(jsonData, 'somaNode')
                fprintf('already parsed from parseNodes.m\n');
            else % could also supply output from loadjson..
                warndlg('input filename as string or struct from loadjson()');
                return
            end
            
            obj.parseDate = jsonData.parseDate;
            obj.analysisDate = datestr(now);
            
            obj.nodeList = jsonData.nodeList;
            
            obj.synData = jsonData.typeData;
            obj.tulipData = jsonData.tulipData;
            
            obj.skeleton = jsonData.skeleton;
            obj.somaNode = jsonData.somaNode;
        end % json2neuron
        
        function addConnectivity(obj, connectivityFile)
            % add something to check for overwrite?
            if ischar(connectivityFile)
                obj.conData = parseConnectivity(connectivityFile);
            elseif isstruct(connectivityFile)
                obj.conData = connectivityFile;
            end
            obj.connectivityDate = datestr(now);
            fprintf('added connectivity\n');
        end % addConnectivity
        
        function source = getSource(obj) %#ok<MANU>
            answer = questdlg('Which block?',...
                'tissue source dialog',...
                'inferior', 'temporal', 'rc1', 'inferior');
            source = answer;
        end % getSource
        
        function printSyn(obj)
            % summarize synapses to cmd line
            rows = ~strcmp(obj.dataTable.LocalName, 'cell') & obj.dataTable.Unique;
            T = obj.dataTable(rows,:);
            
            [a, b] = findgroups(T.LocalName);
            x = splitapply(@numel, T.LocalName, a);
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b{ii});
            end
        end % printSyn
        
        function fh = openApp(obj)
            fh = NeuronApp(obj);
        end
        
        %------------------------------------------------------------------
        %% -------------------------------------------------- GUI setup ---
        %------------------------------------------------------------------
        
        function openUI(obj)
            % this creates the GUI and all the plots. Each plot object is
            % created then set to invisible except for soma.
            obj.fh = figure(...
                'Name', sprintf('Cell %u',obj.cellData.cellNum),...
                'Color', 'w',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultAxesFontName', 'Segoe UI',...
                'DefaultAxesFontSize', 10,...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'Toolbar', 'none');
            pos = obj.fh.Position;
            pos(3) = pos(3) * 1.25;
            pos(4) = pos(4) * 1.1;
            obj.fh.Position = pos;
            
            %% -------------------------------------------------- menu bar ----
            mh.file = uimenu('Parent', obj.fh,...
                'Label', 'File');
            uimenu('Parent', mh.file,...
                'Label', 'Save cell',...
                'Callback', @obj.onMenu_saveCell);
            mh.analysis = uimenu('Parent', obj.fh,...
                'Label', 'Analysis');
            mh.reports = uimenu('Parent', obj.fh,...
                'Label', 'Reports');
            uimenu('Parent', mh.reports,...
                'Label', 'Synapse Overview',...
                'Callback', @obj.onReport_synapseOverview);
            uimenu('Parent', mh.reports,...
                'Label', 'Unknown synapses',...
                'Callback', @obj.onReport_unknown);
            mh.export = uimenu('Parent', obj.fh,...
                'Label', 'Export');
            uimenu('Parent', mh.export,...
                'Label', 'Open figure outside UI',...
                'Callback', @obj.onExport_figure);
            uimenu('Parent', mh.export,...
                'Label', 'Export network',...
                'Callback', @obj.onExport_connectivityTable);
            uimenu('Parent', mh.export,...
                'Label', 'Export neuron',...
                'Callback', @obj.onExport_neuronTable);
            
            %% ------------------------------------------------ tab panels ----
            mainLayout = uix.HBoxFlex('Parent', obj.fh,...
                'Spacing', 5);
            
            obj.handles.tabLayout = uix.TabPanel('Parent', mainLayout,...
                'Padding', 5, 'FontName', 'Segoe UI');
            
            cellInfoTab = uix.Panel('Parent', obj.handles.tabLayout,...
                'Padding', 5);
            plotTab = uix.Panel('Parent', obj.handles.tabLayout,...
                'Padding', 5);
            obj.handles.ax.d3plot = axes('Parent', plotTab);
            axis(obj.handles.ax.d3plot, 'equal');
            tabTab = uix.Panel('Parent', obj.handles.tabLayout,...
                'Padding', 5);
            contactTab = uix.Panel('Parent', obj.handles.tabLayout,...
                'Padding', 5);
            renderTab = uix.Panel('Parent', obj.handles.tabLayout,...
                'Padding', 5);
            obj.handles.histTabs = uix.TabPanel('Parent', tabTab,...
                'Padding', 5, 'FontName', 'Segoe UI');
            somaTab = uix.Panel('Parent', obj.handles.histTabs);
            zTab = uix.Panel('Parent', obj.handles.histTabs);
            
            obj.handles.ax.soma = axes('Parent', somaTab);
            obj.handles.ax.z = axes('Parent', zTab,...
                'YDir', 'reverse');
            obj.handles.tabLayout.TabTitles = {'Cell Info', '3D plot',...
                'Histograms', 'Connectivity', 'Renders'};
            obj.handles.histTabs.TabTitles = {'Soma', 'Z-axis'};
            obj.handles.tabLayout.Selection = 1;
            obj.handles.histTabs.Selection = 1;
            
            %% create the UI panel (left) -------------------------------------
            uiLayout = uix.VBox('Parent', mainLayout,...
                'Spacing', 1, 'Padding', 5);
            %% -------------------------------------------synapse setup -------
            
            tableData = populateSynData(obj.dataTable);
            
            obj.handles.synTable = uitable('Parent', uiLayout);
            set(obj.handles.synTable, 'Data', tableData,...
                'ColumnName', {'Plot', 'Synapse Type', 'N', ' ', 'Bins'},...
                'RowName', [],...
                'ColumnEditable', [true false false false true],...
                'ColumnWidth', {35, 'auto', 40, 25, 30},...
                'FontName', 'Segoe UI', 'FontSize', 10,...
                'CellEditCallback', @obj.onEdit_synTable);
            
            %% ---------------------------------------------- 3d plot setup ----
            obj.handles.clipLayout = uix.HBox('Parent', uiLayout);
            obj.handles.tx.clip = uicontrol('Parent', obj.handles.clipLayout,...
                'Style', 'Text',...
                'String', 'Clip view around soma:');
            obj.handles.cb.aboveSoma = uicontrol('Parent', obj.handles.clipLayout,...
                'Style', 'checkbox',...
                'String', 'Above',...
                'Callback', @obj.clipBySoma);
            obj.handles.cb.belowSoma = uicontrol('Parent', obj.handles.clipLayout,...
                'Style', 'checkbox',...
                'String', 'Below',...
                'Callback', @obj.clipBySoma);
            set(obj.handles.clipLayout, 'Widths', [-1.5 -1 -1]);
            set(obj.handles.clipLayout, 'Visible', 'off');
            
            skelLayout = uix.HBox('Parent', uiLayout);
            obj.handles.cb.addSkeleton = uicontrol('Parent', skelLayout,...
                'Style', 'checkbox', 'Visible', 'off',...
                'String', 'Add skeleton plot',...
                'Callback', @obj.onChanged_addSkeleton);
            obj.handles.pb.skelBack = uicontrol('Parent', skelLayout,...
                'Style', 'push', 'String', '<-',...
                'Visible', 'off',...
                'Callback', @obj.onSelected_deltaSkel);
            obj.handles.tx.skelBins = uicontrol('Parent', skelLayout,...
                'Style', 'text', 'Visible', 'off');
            obj.handles.pb.skelFwd = uicontrol('Parent', skelLayout,...
                'Style', 'push', 'String', '->',...
                'Visible', 'off',...
                'Callback', @obj.onSelected_deltaSkel);
            set(skelLayout, 'Widths', [-2 -0.5 -0.5 -0.5]);
            
            obj.handles.cb.addSoma = uicontrol('Parent', uiLayout,...
                'Style', 'checkbox',...
                'String', 'Add soma',...
                'Value', 1, 'Visible', 'off',...
                'Callback', @obj.onSelected_addSoma);
            
            obj.handles.pb.findConnectivity = uicontrol('Parent', uiLayout,...
                'Style', 'pushbutton',...
                'String', 'Load connectivity',...
                'Visible', 'off',...
                'Callback', @obj.onSelected_loadConnectivity);
            
            obj.handles.cb.limitDegrees = uicontrol('Parent', uiLayout,...
                'Style', 'checkbox',...
                'String', 'Limit to 1 degree',...
                'Visible', 'off',...
                'Callback', @obj.onChanged_limitDegrees);
            
            obj.handles.sliderLayout = uix.HBox('Parent', uiLayout);
            azimuthLayout = uix.VBox('Parent', obj.handles.sliderLayout);
            elevationLayout = uix.VBox('Parent', obj.handles.sliderLayout);
            
            % continuously updating sliders for 3d graph control
            uicontrol('Parent', azimuthLayout,...
                'Style', 'text',...
                'String', 'Azimuth: ');
            obj.handles.sl.azimuth = uicontrol('Parent', azimuthLayout,...
                'Style', 'slider',...
                'Min', 0, 'Max', 360,...
                'SliderStep', [0.0417 0.125],...
                'Value', obj.azel(1));
            obj.handles.jScrollOne = findjobj(obj.handles.sl.azimuth);
            set(obj.handles.jScrollOne,...
                'AdjustmentValueChangedCallback', @obj.onChanged_azimuth);
            
            uicontrol('Parent', elevationLayout,...
                'Style', 'text',...
                'String', 'Elevation: ');
            obj.handles.sl.elevation = uicontrol('Parent', elevationLayout,...
                'Style', 'slider',...
                'Min', 0, 'Max', 360,...
                'SliderStep', [0.0417 0.125],...
                'Value', obj.azel(2));
            obj.handles.jScrollTwo = findjobj(obj.handles.sl.elevation);
            set(obj.handles.jScrollTwo,...
                'AdjustmentValueChangedCallback', @obj.onChanged_elevation);
            
            set(mainLayout, 'Widths', [-1.5 -1]);
            % set(viewLayout, 'Widths', [-1 -1]);
            set(uiLayout, 'Heights', [-4 -1 -1 -1 -1 -1 -1]);
            
            set(obj.handles.sliderLayout, 'Visible', 'off');
            
            % graph all the synapses then set Visibile to off except soma
            obj = populatePlots(obj);
            
            %% --------------------------------------------- connectivity tab ---------
            obj.handles.ax.adj = axes('Parent', contactTab);
            if ~isempty(obj.conData)
                % this is an asymmetric graph
                adjMat = weightedAdjacencyMatrix(obj.conData.contacts, obj.conData.edgeTable.Weight);
                pcolor(obj.handles.ax.adj, adjMat);
                axis(obj.handles.ax.adj, 'square');
                set(obj.handles.ax.adj,...
                    'XTickLabelRotation', 90,...
                    'XTickLabel', obj.conData.nodeTable.CellID,...
                    'XTick', 1:length(adjMat),...
                    'YTickLabel', obj.conData.nodeTable.CellID,...
                    'YTick', 1:length(adjMat),...
                    'FontSize', 7);
            end
            %% -------------------------------------------------- render tab ----------
            renderLayout = uix.VBox('Parent', renderTab,...
                'Spacing', 5);
            obj.handles.ax.render = axes('Parent', renderLayout);
            renderUiLayout = uix.HBox('Parent', renderLayout);
            obj.handles.lst.renders = uicontrol('Parent', renderUiLayout,...
                'Style', 'listbox');
            obj.handles.pb.showRender = uicontrol('Parent', renderUiLayout,...
                'Style', 'push',...
                'String', '<html>show<br/>render',...
                'Callback', @obj.onSelected_showRender);
            set(renderLayout, 'Heights', [-4 -1]);
            set(renderUiLayout, 'Widths', [-5 -1]);
            renderList = populateRenders(obj.cellData.cellNum);
            set(obj.handles.lst.renders, 'String', renderList);
            %% -------------------------------------------------- cell info tab -------
            infoLayout = uix.Panel('Parent', cellInfoTab,...
                'Padding', 5);
            infoGrid = uix.Grid('Parent', infoLayout,...
                'Padding', 5, 'Spacing', 5);
            % left side
            % 1
            basicLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Cell number:');
            obj.handles.ed.cellNum = uicontrol('Parent', basicLayout,...
                'Style', 'edit',...
                'String', num2str(obj.cellData.cellNum));
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Annotator:');
            obj.handles.ed.annotator = uicontrol('Parent', basicLayout,...
                'Style', 'edit', 'String', '');
            % 2
            cellTypeLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', cellTypeLayout,...
                'Style', 'text', 'String', 'Cell Type:');
            obj.handles.lst.cellType = uicontrol('Parent', cellTypeLayout,...
                'Style', 'list', 'String', getCellTypes());
            set(cellTypeLayout, 'Heights', [-1 -3]);
            % 3
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'PR inputs:')
            % 4
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Strata:');
            % 5
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Polarity:')
            % 6
            uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'Notes:');
            % 7
            obj.handles.tx.cellData = uicontrol('Parent', infoGrid,...
                'Style', 'text', 'String', 'No cell data detected');
            
            % right side
            % 1
            sourceLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', sourceLayout,...
                'Style', 'text', 'String', 'Source');
            obj.handles.lst.source = uicontrol('Parent', sourceLayout,...
                'Style', 'list', 'String', {'temporal', 'inferior', 'rc1'});
            switch obj.cellData.source % fix later
                case 'temporal'
                    obj.handles.lst.source.Value = 1;
                case 'inferior'
                    obj.handles.lst.source.Value = 2;
                case 'rc1'
                    obj.handles.lst.source.Value = 3;
            end
            set(sourceLayout, 'Heights', [-1 -3]);
            % 2
            subTypeLayout = uix.VBox('Parent', infoGrid);
            obj.handles.pb.subtype = uicontrol('Parent', subTypeLayout,...
                'Style', 'push', 'String', 'Get subtypes:',...
                'Callback', @obj.onSelected_getSubtypes);
            obj.handles.lst.subtype = uicontrol('Parent', subTypeLayout,...
                'Style', 'list');
            set(subTypeLayout, 'Heights', [-1 -3]);
            % 3
            coneLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.lmcone = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox',...
                'String', 'L/M-cone');
            obj.handles.cb.scone = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox',...
                'String', 'S-cone');
            obj.handles.cb.rod = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox', 'String', 'Rod');
            % 4
            strataLayout = uix.HBox('Parent', infoGrid);
            for ii = 1:5
                strata = sprintf('s%u', ii);
                obj.handles.cb.(strata) = uicontrol('Parent', strataLayout,...
                    'Style', 'checkbox', 'String', strata);
            end
            % 5
            polarityLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.onPol = uicontrol('Parent', polarityLayout,...
                'Style', 'checkbox', 'String', 'ON');
            obj.handles.cb.offPol = uicontrol('Parent', polarityLayout,...
                'Style', 'checkbox', 'String', 'OFF');
            % 6
            obj.handles.ed.notes = uicontrol('Parent', infoGrid,...
                'Style', 'edit', 'String', '');
            % 7
            obj.handles.pb.addData = uicontrol('Parent', infoGrid,...
                'Style', 'push', 'String', 'Add cell data',...
                'Callback', @obj.onSelected_addCellData);
            
            set(infoGrid, 'Widths', [-1 -1], 'Heights',[-2 -3 -1 -1 -1 -1 -1]);
            
            % check out cell info
            if obj.cellData.flag
                [obj.handles, titlestr] = loadCellData(obj.handles, obj.cellData);
                if ~isempty(titlestr)
                    set(obj.fh, 'Name', titlestr);
                end
            else
                set(obj.handles.lst.cellType, 'Value', 1);
                set(obj.handles.lst.subtype, 'Enable', 'off',...
                    'String', {'Pick', 'cell type', 'first'})
            end
            
            % setup some final callbacks
            set(obj.handles.tabLayout, 'SelectionChangedFcn', @obj.onChanged_tab);
            set(obj.handles.histTabs, 'SelectionChangedFcn', @obj.onChanged_histTab);
        end % openGUI
        
        %-------------------------------------------------------------------------
        %% --------------------------------------------------------- callbacks ---
        %-------------------------------------------------------------------------
        
        %% ------------------------------------------------ render callbacks -----
        function onSelected_showRender(obj,~,~)
            imName = obj.handles.lst.renders.String{obj.handles.lst.renders.Value};
            imName = [getFilepaths('render') imName];
            im = imread(imName);
            imshow(im(:,:,1:3), 'Parent', obj.handles.ax.render,...
                'InitialMagnification', 'fit');
        end % onSelected_showRender
        
        %% ------------------------------------------------ 3d plot callbacks -----
        function onChanged_azimuth(obj, ~, ~)
            obj.azel(1) = get(obj.handles.sl.azimuth, 'Value');
            view(obj.handles.ax.d3plot, obj.azel);
        end % onChanged_azimuth
        
        function onChanged_elevation(obj, ~, ~)
            obj.azel(2) = get(obj.handles.sl.elevation, 'Value');
            view(obj.handles.ax.d3plot, obj.azel);
        end % onChanged_elevation
        
        function onEdit_synTable(obj, src, eventdata)
            tableData = src.Data;
            tableInd = eventdata.Indices;
            switch tableInd(2)
                case 1
                    tof = tableData(tableInd(1), tableInd(2));
                    if tof{1}
                        obj.addSyn(tableInd(1));
                    else
                        obj.rmSyn(tableInd(1));
                    end
                case 5
                    obj.deltaSomaHist(tableInd(1));
            end
            src.Data = tableData; % update table
        end % onEdit_synTable
        
        function onChanged_addSkeleton(obj,~,~)
            if get(obj.handles.cb.addSkeleton, 'Value') == 1
                set(obj.handles.skeletonLine, 'Visible', 'on');
                set(obj.handles.skeletonBins, 'Visible', 'on');
            else
                set(obj.handles.skeletonLine, 'Visible', 'off');
                set(obj.handles.skeletonBins, 'Visible', 'off');
            end
        end % onSelected_addSkeleton
        
        function onSelected_deltaSkel(obj, src, ~)
            nbin = str2double(get(obj.handles.tx.skelBins, 'String'));
            switch src.String
                case '->'
                    nbin = nbin + 1;
                case '<-'
                    nbin = nbin - 1;
            end
            if nbin == 0
                return;
            end
            skelRow = strcmp(obj.dataTable.LocalName, 'cell');
            xyz = table2array(obj.dataTable(skelRow, 'XYZum'));
            [counts, bins] = histcounts(xyz(:,3), nbin+1);
            cent = bins(1:end-1) + (bins(2)-bins(1))/2;
            set(obj.handles.skeletonBins, 'XData', counts, 'YData', cent);
            set(obj.handles.tx.skelBins, 'String', num2str(nbin));
        end % onSelected_deltaSkel
        
        function onSelected_addSoma(obj,~,~)
            if get(obj.handles.cb.addSoma, 'Value') == 1
                set(obj.handles.somaLine, 'Visible', 'on');
            else
                set(obj.handles.somaLine, 'Visible', 'off');
            end
        end % onSelected_addSoma
        
        function clipBySoma(obj, ~, ~)
            somaXYZ = getSomaXYZ(obj);
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
        %% ----------------------------------------------- network callbacks -----
        
        function onChanged_limitDegrees(obj, ~,~)
            % this is totally repetitive, fix at some point
            if get(obj.handles.cb.limitDegrees, 'Value') == 1
                % find only the contacts containing target neuron
                cellNode = find(obj.conData.nodeTable.CellID == obj.cellData.cellNum);
                hasNeuron = bsxfun(@eq, cellNode, obj.conData.contacts);
                ind = find(sum(hasNeuron, 2));
                adjMat = weightedAdjacencyMatrix(obj.conData.contacts(ind,:),...
                    obj.conData.edgeTable.Weight(ind,:));
            else
                adjMat = weightedAdjacencyMatrix(obj.conData.contacts,...
                    obj.conData.edgeTable.Weight);
            end
            
            cla(obj.handles.ax.adj);
            pcolor(obj.handles.ax.adj, adjMat);
            axis(obj.handles.ax.adj, 'square');
            set(obj.handles.ax.adj,...
                'XTickLabelRotation', 90,...
                'XTickLabel', obj.conData.nodeTable.CellID,...
                'XTick', 1:length(adjMat),...
                'YTickLabel', obj.conData.nodeTable.CellID,...
                'YTick', 1:length(adjMat),...
                'FontSize', 7);
            
            if get(obj.handles.cb.limitDegrees, 'Value') == 1
                set(obj.handles.ax.adj,...
                    'XTickLabel', obj.conData.nodeTable.CellID(ind,:),...
                    'YTickLabel', obj.conData.nodeTable.CellID(ind,:));
            end
        end % onChanged_limitDegrees
        
        function onSelected_loadConnectivity(obj, ~, ~)
            dataDir = getFilepaths('data');
            if ~isempty(dataDir)
                cd(dataDir);
            end
            
            [fileName, filePath] = uigetfile('*.json', 'Pick a network:');
            
            obj.addConnectivity([filePath, fileName]);
        end % onSelected_loadConnectivity
        
        %% ---------------------------------------------- histogram callbacks -----
        function onChanged_tab(obj,~,~)
            set(obj.handles.cb.addSoma, 'Visible', 'off');
            set(obj.handles.cb.addSkeleton, 'Visible', 'off');
            set(obj.handles.pb.findConnectivity, 'Visible', 'off');
            set(obj.handles.sliderLayout, 'Visible', 'off');
            set(obj.handles.clipLayout, 'Visible', 'off');
            set(obj.handles.cb.limitDegrees, 'Visible', 'off');
            set(obj.handles.tx.skelBins, 'Visible', 'off');
            set(obj.handles.pb.skelFwd, 'Visible', 'off');
            set(obj.handles.pb.skelBack, 'Visible', 'off');
            
            switch obj.handles.tabLayout.Selection
                case 1
                case 2
                    set(obj.handles.clipLayout, 'Visible', 'on');
                    set(obj.handles.sliderLayout, 'Visible', 'on');
                    set(obj.handles.cb.addSoma, 'Visible', 'on');
                    set(obj.handles.cb.addSkeleton, 'Visible', 'on');
                case 3
                    set(obj.handles.cb.addSkeleton, 'Visible', 'on');
                    set(obj.handles.tx.skelBins, 'Visible', 'on');
                    set(obj.handles.pb.skelFwd, 'Visible', 'on');
                    set(obj.handles.pb.skelBack, 'Visible', 'on');
                case 4
                    set(obj.handles.pb.findConnectivity, 'Visible', 'on');
                    set(obj.handles.cb.limitDegrees, 'Visible', 'on');
            end
        end % onChanged_tab
        
        function onChanged_histTab(obj,~,~)
            switch obj.handles.histTabs.Selection
                case 1 % soma plot
                    for ii = 1:length(obj.synList)
                        obj.handles.synTable.Data{ii,5} = obj.handles.numBins(1,ii);
                    end
                case 2 % z-axis plot
                    for ii = 1:length(obj.synList)
                        obj.handles.synTable.Data{ii,5} = obj.handles.numBins(2,ii);
                    end
            end
        end % onChanged_histTab
        %% -------------------------------------------------- menu callbacks ------
        function onMenu_saveCell(obj,~,~)
            % this will actually create and save a new object without all the
            % figure handles and graph utils
            selection = questdlg(...
                'This will close the GUI. Continue?',...
                'Save cell dialog',...
                'Yes', 'No', 'Yes');
            switch selection
                case 'Yes'
                    newNeuron = obj;
                    obj.saveDir = getFilepaths('data');
                    newNeuron.handles = [];
                    newNeuron.fh = [];
                    uisave('newNeuron', sprintf('c%u.mat', obj.cellData.cellNum));
                    fprintf('Saved!\n');
                    delete(gcf);
                case 'No'
                    return;
            end
        end % onMenu_saveCell
        
        function onReport_unknown(obj,~,~)
            r = strcmp(obj.dataTable, 'unknown') == 1;
            newTable = obj.dataTable(r,:);
            
            fprintf('found %u unknown synapses\n', size(newTable, 1));
            selection = questdlg(...
                sprintf('Save %u unknown synapses?', size(newTable, 1)),...
                'Save Dialog',...
                'Yes', 'No', 'Yes');
            switch selection
                case 'Yes'
                    fid = fopen(sprintf('c%u unknown.txt', obj.cellData.cellNum), 'w');
                    fprintf(fid, '%u \n', locID);
                    fclose(fid);
                    fprintf('%u unknown synapses saved\n', length(locID));
                case 'No'
                    return;
            end
        end % onReport_unknown
        
        function onExport_connectivityTable(obj,~,~)
            % save connectivity table as .csv or .txt
            if ~isempty(getFilepaths('data'))
                cd(getFilepaths('data'));
            end
            dataDir = uigetdir(cd, 'Pick a directory');
            if isempty(dataDir)
                return;
            end
            selection = questdlg('File format?',...
                'Save dialog',...
                'Excel', 'Text', 'Excel');
            switch selection
                case 'Excel'
                    fileName = [dataDir filesep sprintf('c%u_networkEdges.xls', obj.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.conData.edgeTable));
                    fileName = [dataDir filesep sprintf('c%u_networkNodes.xls', obj.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.conData.nodeTable));
                case 'Text'
                    obj.conData.edgeTable
                    obj.conData.nodeTable
            end
            fprintf('saved!\n');
        end % onExport_connectivityTable
        
        function onExport_neuronTable(obj, ~, ~)
            % save neuron table to excel
            if ~isempty(getFilepaths('data'))
                cd(getFilepaths('data'));
            end
            dataDir = uigetdir(cd, 'Pick a directory');
            if isempty(dataDir)
                return;
            end
            selection = questdlg('File format?',...
                'Save dialog',...
                'Excel', 'Text', 'Excel');
            switch selection
                case 'Excel'
                    fileName = [dataDir filesep sprintf('c%u_dataTable.xls', obj.cellData.cellNum)];
                    xlswrite(fileName, table2cell(obj.dataTable));
                case 'Text'
                    obj.dataTable
            end
            fprintf('saved!\n');
        end % onExport_neuronTable
        
        function onExport_figure(obj, ~, ~)
            switch obj.handles.tabLayout.Selection
                case 2 % 3d plot
                    ax = obj.handles.ax.d3plot;
                case 3
                    if obj.handles.histTabs.Selection == 1 % soma dist
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
            % get only the visible components
            newAxes = copyobj(ax, figure);
            set(newAxes, 'ActivePositionProperty', 'outerposition')
            set(newAxes, 'Units', 'normalized')
            set(newAxes, 'OuterPosition', [0 0 1 1])
            set(newAxes, 'Position', [0.1300 0.1100 0.7750 0.8150])
            title(newAxes, ['c' num2str(obj.cellData.cellNum)]);
            % get rid of invisible lines
            lines = findall(newAxes, 'Type', 'Line', 'Visible', 'off');
            delete(lines);
        end % onExport_figure
        
        function onReport_synapseOverview(obj,~,~)
            selection = questdlg('Save synapse overview?',...
                'Save dialog',...
                'Yes', 'No', 'Yes');
            switch selection
                case 'Yes'
                    r = ~strcmp(obj.dataTable.LocalName, 'cell') & obj.dataTable.Unique == 1;
                    newTable = obj.dataTable(r,:);
                    [G, names] = findgroups(newTable.LocalName);
                    numUnique = splitapply(@numel, newTable.LocalName, G);
                    
                    fid = fopen(sprintf('c%u_overview.txt', obj.cellData.cellNum), 'w');
                    fprintf(fid, 'c%u Synapses:\n', obj.cellData.cellNum);
                    for ii = 1:length(names)
                        fprintf(fid, '%u - %s\n', numUnique(ii), names{ii});
                    end
                    fprintf(fid, '\ngenerated on %s', datestr(now));
                    fclose(fid);
                case 'No'
                    return;
            end
        end % onReport_synapseOverview
        %% ---------------------------------------------- cellData callbacks ------
        function onSelected_getSubtypes(obj,~,~)
            cType = obj.handles.lst.cellType.String{obj.handles.lst.cellType.Value};
            if strcmp(cType, 'unknown')
                set(obj.handles.pb.subtype, 'String', 'Pick a type first!');
            else
                set(obj.handles.lst.subtype, 'String', getCellSubtypes(cType),...
                    'Enable', 'on');
            end
        end % onSelected_getSubtypes
        
        function onSelected_addCellData(obj,~,~)
            % TODO: more input checks
            if str2double(obj.handles.ed.cellNum.String) ~= 0
                obj.cellData.cellNum = str2double(obj.handles.ed.cellNum.String);
            end
            obj.cellData.cellType = obj.handles.lst.cellType.String{obj.handles.lst.cellType.Value};
            obj.cellData.subType = obj.handles.lst.subtype.String{obj.handles.lst.subtype.Value};
            obj.cellData.annotator = get(obj.handles.ed.annotator, 'String');
            obj.cellData.source = obj.handles.lst.source.String{obj.handles.lst.source.Value};
            obj.cellData.onoff(1) = obj.handles.cb.onPol.Value;
            obj.cellData.onoff(2) = obj.handles.cb.offPol.Value;
            
            inputTypes = {'lmcone', 'scone', 'rod'};
            for ii = 1:length(inputTypes)
                if obj.handles.cb.(inputTypes{ii}).Value == 1
                    obj.cellData.inputs(ii) = 1;
                else
                    obj.cellData.inputs(ii) = 0;
                end
            end
            
            strata = 1:5;
            for ii = 1:length(strata)
                obj.cellData.strata(1,ii) = obj.handles.cb.(sprintf('s%u', ii)).Value;
            end
            
            if ~isempty(obj.handles.ed.notes.String)
                % add to notes with timestamp
                if ~isempty(obj.cellData.notes)
                    obj.cellData.notes = [obj.cellData.notes '\n'];
                end
                obj.cellData.notes = [obj.cellData.notes,...
                    datestr(now) ' - ' get(obj.handles.ed.notes, 'String')];
            end
            
            % triggers loadCellData on next openGUI call
            obj.cellData.flag = true;
            
            % so you know it actually saved
            set(obj.handles.tx.cellData, 'String', 'Cell data added!');
            
        end % onSelected_addCellData
        
        %--------------------------------------------------------------------------
        %% -------------------------------------------------------- functions -----
        %--------------------------------------------------------------------------
        
        %% ------------------------------------------------- plot functions -------
        function addSyn(obj, whichSyn)
            set(obj.handles.lines(whichSyn), 'Visible', 'on');
            set(obj.handles.somaBins(whichSyn), 'Visible', 'on');
            set(obj.handles.zBins(whichSyn), 'Visible', 'on');
        end % addSyn
        
        function rmSyn(obj, whichSyn)
            set(obj.handles.lines(whichSyn), 'Visible', 'off');
            set(obj.handles.somaBins(whichSyn), 'Visible', 'off');
            set(obj.handles.zBins(whichSyn), 'Visible', 'off');
        end % rmSyn - TODO: consolidate with addSyn
        
        function deltaSomaHist(obj, synInd)
            % TODO: expand to all bar plots
            if nargin < 2
                synInd = 1:length(obj.synList);
            end
            switch obj.handles.histTabs.Selection
                case 1 % soma distance histogram
                    for ii = 1:length(synInd)
                        [counts, binCenters] = obj.getHist(obj.somaDist{synInd(ii), 1}, obj.handles.synTable.Data{synInd(ii),5});
                        set(obj.handles.somaBins(ii),...
                            'XData', binCenters, 'YData', counts);
                    end
                case 2 % z-axis histogram
                    for ii = 1:length(synInd)
                        xyz = getSynXYZ(obj.dataTable, obj.synList{synInd(ii)});
                        [counts, binCenters] = obj.getHist(xyz(:, 3), obj.handles.synTable.Data{synInd(ii),5});
                        set(obj.handles.zBins(synInd(ii)), 'XData', counts, 'YData', binCenters);
                    end
            end
        end % deltaSomaHist
    end % methods
    
    %% ------------------------------------------------- support functions ----
    methods (Static)
        
        function x = setCellColor_Local(hexColor, txt)
            x = ['<html><table border=0 width=200 bgcolor=',...
                hexColor, '><TR><TD>', txt, '</TD></TR> </table></html>'];
        end % setCellColor
        
        function [counts, binCenters] = getHist(x, nBins)
            if nargin < 2
                [counts, bins] = histcounts(x);
            else
                [counts, bins] = histcounts(x, nBins);
            end
            binInc = bins(2)-bins(1);
            binCenters = bins(1:end-1) + binInc/2;
        end % getHist
        
        function xyz = normXYZ(xyz)
            xyz = bsxfun(@minus, xyz, min(xyz));
        end % normXYZ
        
        function z = micronZ(z, source)
            switch source
                case 'inferior'
                    z = z .* 90;
                case 'temporal'
                    z = z .* 70;
            end
        end % micronZ
        
        function xy = micronXY(xy)
            xy = xy .* 5; % pix --> nm
            xy = xy ./ 1000; % nm --> um
        end % micronXY
        
        function xyz = pix2micron(xyz)
            % 5nm to 1 pix
            xyz = 5 .* xyz;
            % 1000 nm to 1 micron
            xyz = xyz ./ 1000;
        end % pix2micron
        
    end % static methods
end % classdef
