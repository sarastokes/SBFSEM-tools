classdef NeuronApp < handle
    % Neuron class UI - work in progress
    
    properties (SetAccess = private)
        handles
        data
        neuron
    end
    
    properties (Hidden, Transient)
        azel = [0 90]  % rotation of 3d plot
        somaDist
    end
    
  %% Constructor
    methods
        function obj = NeuronApp(Neuron)
            % CONSTRUCTOR  NeuronApp

            if ~isa(Neuron, 'Neuron')
                error('Input a Neuron object');
            end
            obj.neuron = Neuron;
            
            createUI(obj);
        end % constructor
    end % methods
    
    %% UI Setup methods
    methods (Access = private)
        function createUI(obj)
            fh = figure('Name', sprintf('Cell %u', obj.neuron.cellData.cellNum),...
                'Color', 'w',...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'DefaultUicontrolFontSize', 10,...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'NumberTitle', 'off');
            
            pos = fh.Position;
            pos(3) = pos(3) * 1.25;
            pos(4) = pos(4) * 1.1;
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
            mh.analysis = uimenu('Parent', obj.handles.fh,...
                'Label', 'Analysis');
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
                'Spacing', 5);
            
            obj.handles.layouts.tab = uix.TabPanel('Parent', obj.handles.layouts.main,...
                'Padding', 5, 'FontName', 'Segoe UI');
            
            tabs.cellInfo = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5);
            tabs.plot = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5);
            obj.handles.ax.d3plot = axes('Parent', tabs.plot);
            axis(obj.handles.ax.d3plot, 'equal');
            tabTab = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5);

            % histogram tabs and sub-tabs
            tabs.hist = uix.TabPanel('Parent', tabTab,...
                'Padding', 5, 'FontName', 'Segoe UI');
            tabs.soma = uix.Panel('Parent', tabs.hist);
            tabs.z = uix.Panel('Parent', tabs.hist);
            obj.handles.ax.soma = axes('Parent', tabs.soma);
            obj.handles.ax.z = axes('Parent', tabs.z,...
                'YDir', 'reverse');
            tabs.hist.TabTitles = {'Soma', 'Z-axis'};
            tabs.hist.Selection = 1;
            
            tabs.contacts = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5);
            tabs.render = uix.Panel('Parent', obj.handles.layouts.tab,...
                'Padding', 5);
            
            obj.handles.layouts.tab.TabTitles = {'Cell Info', '3D plot',...
                'Histograms', 'Connectivity', 'Renders'};
            obj.handles.layouts.tab.Selection = 1;

            % add tabs to handles structure
            obj.handles.tabs = tabs;
            
            obj.handles.layouts.ui = uix.VBox('Parent', obj.handles.layouts.main,...
                'Spacing', 1, 'Padding', 5);
                                                       
            % create the synapse table
            tableData = populateSynData(obj.neuron.dataTable);
            obj.handles.synTable = uitable('Parent', obj.handles.layouts.ui);
            set(obj.handles.synTable, 'Data', tableData,...
                'ColumnName', {'Plot', 'Synapse', 'N', ' ', 'Bins'},...
                'ColumnEditable', [true false false false true],...
                'ColumnWidth', {35, 'auto', 40, 25, 30},...
                'RowName', [],...
                'FontName', get(obj.handles.fh, 'DefaultUiControlFontName'),...
                'CellEditCallback', @obj.onEdit_synTable);   
        end % createUI_main
        
        function createUI_cellData(obj)
            infoLayout = uix.Panel('Parent', obj.handles.tabs.cellInfo,...
                'Padding', 5);
            infoGrid = uix.Grid('Parent', infoLayout,...
                'Padding', 5, 'Spacing', 5);
            
            % left side
            basicLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Cell number:');
            obj.handles.ed.cellNum = uicontrol('Parent', basicLayout,...
                'Style', 'edit', 'String', num2str(obj.neuron.cellData.cellNum));
            uicontrol('Parent', basicLayout,...
                'Style', 'text', 'String', 'Annotator:');
            obj.handles.ed.annotator = uicontrol('Parent', basicLayout,...
                'Style', 'edit', 'String', '');
            
            cellTypeLayout = uix.VBox('Parent', infoGrid);
            uicontrol('Parent', cellTypeLayout,...
                'Style', 'text', 'String', 'Cell Type:');
            obj.handles.lst.cellType = uicontrol('Parent', cellTypeLayout,...
                'Style', 'list', 'String', getCellTypes());
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
            obj.handles.lst.source = uicontrol('Parent', sourceLayout,...
                'Style', 'list', 'String', {'temporal', 'inferior', 'rc1'});
            switch obj.neuron.cellData.source % fix later
                case 'temporal'
                    obj.handles.lst.source.Value = 1;
                case 'inferior'
                    obj.handles.lst.source.Value = 2;
                case 'rc1'
                    obj.handles.lst.source.Value = 3;
            end
            set(sourceLayout, 'Heights', [-1 -3]);
            subTypeLayout = uix.VBox('Parent', infoGrid);
            obj.handles.pb.subtype = uicontrol('Parent', subTypeLayout,...
                'Style', 'push', 'String', 'Get subtypes:',...
                'Callback', @obj.getSubtypes);
            obj.handles.lst.subtype = uicontrol('Parent', subTypeLayout,...
                'Style', 'list');
            set(subTypeLayout, 'Heights', [-1 -3]);
            
            coneLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.lmcone = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox',...
                'String', 'L/M-cone');
            obj.handles.cb.scone = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox',...
                'String', 'S-cone');
            obj.handles.cb.rod = uicontrol('Parent', coneLayout,...
                'Style', 'checkbox', 'String', 'Rod');

            strataLayout = uix.HBox('Parent', infoGrid);
            for ii = 1:5
                strata = sprintf('s%u', ii);
                obj.handles.cb.(strata) = uicontrol('Parent', strataLayout,...
                    'Style', 'checkbox', 'String', strata);
            end
            polarityLayout = uix.HBox('Parent', infoGrid);
            obj.handles.cb.onPol = uicontrol('Parent', polarityLayout,...
                'Style', 'checkbox', 'String', 'ON');
            obj.handles.cb.offPol = uicontrol('Parent', polarityLayout,...
                'Style', 'checkbox', 'String', 'OFF');
            obj.handles.ed.notes = uicontrol('Parent', infoGrid,...
                'Style', 'edit', 'String', '');
            obj.handles.pb.addData = uicontrol('Parent', infoGrid,...
                'Style', 'push', 'String', 'Add cell data',...
                'Callback', @obj.addCellData);
            
            set(infoGrid, 'Widths', [-1 -1], 'Heights',[-2 -3 -1 -1 -1 -1 -1]);
            % check for cell info
            if obj.neuron.cellData.flag
                [obj.handles, titlestr] = loadCellData(obj.handles, obj.neuron.cellData);
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
            obj.handles.tx.clip = uicontrol('Parent', obj.handles.layouts.clip,...
                'Style', 'Text',...
                'String', 'Clip view around soma:');
            obj.handles.cb.aboveSoma = uicontrol('Parent', obj.handles.layouts.clip,...
                'Style', 'checkbox',...
                'String', 'Above',...
                'Callback', @obj.clipBySoma);
            obj.handles.cb.belowSoma = uicontrol('Parent', obj.handles.layouts.clip,...
                'Style', 'checkbox',...
                'String', 'Below',...
                'Callback', @obj.clipBySoma);
            set(obj.handles.layouts.clip,... 
                'Widths', [-1.5 -1 -1], 'Visible', 'off');
            
            skelLayout = uix.HBox('Parent', obj.handles.layouts.ui);
            obj.handles.cb.addSkeleton = uicontrol('Parent', skelLayout,...
                'Style', 'checkbox', 'Visible', 'off',...
                'String', 'Add skeleton plot',...
                'Callback', @obj.addSkeleton);
            obj.handles.pb.skelBack = uicontrol('Parent', skelLayout,...
                'Style', 'push', 'String', '<-',...
                'Visible', 'off');
            obj.handles.tx.skelBins = uicontrol('Parent', skelLayout,...
                'Style', 'text');
            obj.handles.pb.skelFwd = uicontrol('Parent', skelLayout,...
                'Style', 'push', 'String', '->');
            set([obj.handles.pb.skelFwd, obj.handles.pb.skelBack],...
                'Visible', 'off',...
                'Callback', @obj.deltaSkeleton);
            set(skelLayout, 'Widths', [-2 -0.5 -0.5 -0.5]);
            
            obj.handles.cb.addSoma = uicontrol('Parent', obj.handles.layouts.ui,...
                'Style', 'checkbox',...
                'String', 'Add soma',...
                'Value', 1, 'Visible', 'off',...
                'Callback', @obj.addSoma);
            
            obj.handles.pb.findConnectivity = uicontrol('Parent', obj.handles.layouts.ui,...
                'Style', 'pushbutton',...
                'String', 'Load connectivity',...
                'Visible', 'off',...
                'Callback', @obj.loadNetwork);
            
            obj.handles.cb.limitDegrees = uicontrol('Parent', obj.handles.layouts.ui,...
                'Style', 'checkbox',...
                'String', 'Limit to 1 degree',...
                'Visible', 'off',...
                'Callback', @obj.limitDegrees);
            
            obj.handles.layouts.slider = uix.HBox('Parent', obj.handles.layouts.ui);
            azimuthLayout = uix.VBox('Parent', obj.handles.layouts.slider);
            elevationLayout = uix.VBox('Parent', obj.handles.layouts.slider);
            
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
                'AdjustmentValueChangedCallback', @obj.setAzimuth);
            
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
                'AdjustmentValueChangedCallback', @obj.setElevation);
            
            set(obj.handles.layouts.main, 'Widths', [-1.5 -1]);
            % set(viewLayout, 'Widths', [-1 -1]);
            set(obj.handles.layouts.ui, 'Heights', [-4 -1 -1 -1 -1 -1 -1]);
            
            set(obj.handles.layouts.slider, 'Visible', 'off');
            
            % graph all the synapses then set Visibile to off except soma
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
                'Spacing', 5);
            obj.handles.ax.render = axes('Parent', renderLayout);
            renderUiLayout = uix.HBox('Parent', renderLayout);
            obj.handles.lst.renders = uicontrol('Parent', renderUiLayout,...
                'Style', 'listbox');
            obj.handles.pb.showRender = uicontrol('Parent', renderUiLayout,...
                'Style', 'push',...
                'String', '<html>show<br/>render',...
                'Callback', @obj.showRender);
            set(renderLayout, 'Heights', [-4 -1]);
            set(renderUiLayout, 'Widths', [-5 -1]);
            % populateRenders searches for 'c#' matches in blender dir
            renderList = populateRenders(obj.neuron.cellData.cellNum);
            set(obj.handles.lst.renders, 'String', renderList);
        end % createUI_blender      
        
        function populateGraphs(obj)
            % POPULATEGRAPHS  Creates 3d plot and histogram data
            sc = getStructureColors();
            T = obj.neuron.dataTable;
            
            somaXYZ = getSomaXYZ(obj.neuron);
            
            % throw out the cell body and multiple slide synapses
            rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
            % make a new table with only unique synapses
            synTable = T(rows, :);
            % group by LocalName
            [~, names] = findgroups(synTable.LocalName);
            % how many synapse types
            numSyn = numel(names);
            
            obj.handles.numBins = zeros(2, numSyn);
            obj.neuron.somaDist = cell(numSyn, 1);
            
            % create the plots by synapse type
            for ii = 1:numSyn
                % synapse 3d plot
                xyz = getSynXYZ(T, names{ii});
                obj.handles.lines(ii) = line('Parent', obj.handles.ax.d3plot,...
                    'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
                    'Color', sc(names{ii}), 'Marker', '.',...
                    'MarkerSize', 10, 'LineStyle', 'none',...
                    'Visible', 'off');
                
                % synapse distance histograms
                obj.somaDist{ii,1} = fastEuclid3d(somaXYZ, xyz);
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
            ylabel(obj.handles.ax.z, 'slice (z-axis)'); 
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
            [counts, bins] = histcounts(xyz(:,3));
            binInc = bins(2) - bins(1);
            cent = bins(1:end-1) + binInc/2;
            obj.handles.skeletonBins = line('Parent', obj.handles.ax.z,...
                'XData', counts, 'YData', cent,...
                'LineWidth', 2, 'Color', 'k',...
                'Visible', 'off');
            set(obj.handles.tx.skelBins, 'String', num2str(length(cent)));            

            % plot the soma - keep it visible
            obj.handles.somaLine = line('Parent', obj.handles.ax.d3plot,...
                'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
                'Marker', '.', 'MarkerSize', 20, 'Color', 'k');
            
            axis(obj.handles.ax.d3plot, 'equal');
            xlabel(obj.handles.ax.d3plot, 'x-axis');
            ylabel(obj.handles.ax.d3plot, 'y-axis');
            zlabel(obj.handles.ax.d3plot, 'z-axis');            
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
        
% ------------------------------------------------ save callbacks ---------        
        function saveNeuron(obj, ~, ~)
            % SAVENEURON  Save changes to neuron
            uisave(obj.neuron, sprintf('c%u', obj.neuron.cellData.cellNum));
            fprintf('Saved/n!');
        end % saveNeuron
        
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
            dataDir = getFilepaths('data');
            if ~isempty(dataDir)
                cd(dataDir);
            end
            
            [fileName, filePath] = uigetfile('*.json', 'Pick a network:');
            
            obj.neuron.addConnectivity([filePath, fileName]);
        end % loadNetwork
        
        function limitDegrees(obj, ~,~)
            % LIMITDEGREES  Change degrees of separation in network matrix
            % TODO: this is totally repetitive, fix at some point
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
                    obj.deltaSomaHist(tableInd(1));
            end
            src.Data = tableData; % update table
        end % onEdit_synTable       
        
        function addSkeleton(obj,~,~)
            % ADDSKELETON  Toggles display of neuron skeleton
            if get(obj.handles.cb.addSkeleton, 'Value') == 1
                set([obj.handles.skeletonLine,... 
                    obj.handles.skeletonBins], 'Visible', 'on');
            else
                set([obj.handles.skeletonLine,... 
                    obj.handles.skeletonBins], 'Visible', 'off');
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

% ----------------------------------------------- histogram callbacks -----       
        function deltaSkeleton(obj, src, ~)
            % DELTASKELETON  Change bin # for skeleton histogram
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
        end % deltaSkeleton
        
% ------------------------------------------ tab navigation callbacks -----
        function changeTab(obj, ~, ~)
            % CHANGETAB  Toggles component visibility
            
            % all component visibility defaults to 'off'
            set([obj.handles.cb.addSoma, obj.handles.cb.addSkeleton,...
                obj.handles.pb.findConnectivity,...
                obj.handles.pb.skelFwd, obj.handles.pb.skelBack,...
                obj.handles.tx.skelBins, obj.handles.cb.limitDegrees],...
                'Visible', 'off');
            set([obj.handles.layouts.slider, obj.handles.layouts.clip],...
                'Visible', 'off');
            
            switch obj.handles.layouts.tab.Selection
                case 1 % cell info tab
                case 2 % 3d plot tab
                    set([obj.handles.layouts.clip, obj.handles.layouts.slider,...
                        obj.handles.cb.addSoma, obj.handles.cb.addSkeleton],...
                        'Visible', 'on');
                case 3 % histogram tab
                    set([obj.handles.cb.addSkeleton, obj.handles.pb.skelBack,... 
                        obj.handles.pb.skelFwd], 'Visible', 'on');
                case 4 % network tab
                    set([obj.handles.pb.findConnectivity,... 
                        obj.handles.cb.limitDegrees],...
                        'Visible', 'on');
            end
        end % changeTab
        
        function changeHistogram(obj,~,~)
            % CHANGEHISTOGRAM  Updates bin # display for each histogram
            switch obj.handles.tabs.hist.Selection
                case 1 % soma plot
                    for ii = 1:length(obj.synList)
                        obj.handles.synTable.Data{ii,5} = obj.handles.numBins(1,ii);
                    end
                case 2 % z-axis plot
                    for ii = 1:length(obj.synList)
                        obj.handles.synTable.Data{ii,5} = obj.handles.numBins(2,ii);
                    end
            end
        end % changeHistogram
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
            [dataDir, fileType] = setupSave();
            switch fileType
                case 'Excel'
                    fileName = [dataDir filesep... 
                        sprintf('c%u_dataTable.xls', obj.neuron.dataTable)];
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
                'Position', [0.13 0.11 0.775 0.815]);
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
    end % methods private
    
    methods (Static)
        function x = setTableCellColor(hexColor, txt)
            % SETTABLECELLCOLOR  Use HTML to create legend cells
            x = ['<html><table border=0 width=200 bgcolor=',...
                hexColor, '><TR><TD>', txt, '</TD></TR> </table></html>'];
        end % setTableCellColor

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

        function xyz = normXYZ(xyz)
            % NORMXYZ  Normalize the location in Viking values
            xyz = bsxfun(@minus, xyz, min(xyz));
        end % normXYZ
        
        function [dataDir, fileType] = setupSave()
            % SETUPSAVE  Dialog used by reports to set save options
            if ~isempty(getFilepaths('data'))
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
    end % methods static
end % classdef
