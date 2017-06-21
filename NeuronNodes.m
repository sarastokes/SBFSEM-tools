classdef NeuronNodes < handle
	% Analysis and graphs based only on nodes, without edges

properties
    % this comes from tulip too but could edit if needed
    somaNode % largest "cell" node

    cellData
    fname
    saveDir
end

properties (SetAccess = private, GetAccess = public)
% these are properties parsed from tulip data
    nodeList % all nodes
    skeleton % just the "cell" nodes
	nodeData % nodeData consists of containers.Map bins for each property (the
	% columns in Tulip). The properties included are: LocationInViking,
	% LocationID, ParentID, StructureType, Tags, ViewSize, OffEdge and
	% Terminal. See parseNodes.m for more details

	synData % this contains data about each synapse type in the cell
    tulipData % currently not using, might get rid of
	parseDate % date .tlp or .tlpx file created
	analysisDate % date run thru NeuronNodes
end

properties
	fh
	handles
	azel % current azimuth + elevation view
	azelInc
	somaDist
end

methods
	function obj = NeuronNodes(cellData)
		% detect input type
		if ischar(cellData) && strcmp(cellData(end-3:end), 'json') %#ok<ALIGN>
			fprintf('parsing with loadjson.m...');
			cellData = loadjson(cellData);
			fprintf('parsed\n');
            cellData = parseNodes(cellData);
        elseif isstruct(cellData) && isfield(cellData, 'version')
            cellData = parseNodes(cellData);
        elseif isstruct(cellData) && isfield(cellData, 'somaNode')
            fprintf('already parsed from parseNodes.m\n');
        else % could also supply output from loadjson..
			warndlg('input filename as string or struct from loadjson()');
            return;
        end

        % move to obj properties (this allows cellData output to be used
        % independently of NeuronNodes object too
        obj.fname = cellData.fileName;
        obj.parseDate = cellData.parseDate;
        obj.analysisDate = datestr(now);

        obj.nodeList = cellData.nodeList;

        obj.synData = cellData.typeData;
        obj.tulipData = cellData.tulipData;
        obj.nodeData = cellData.props;

        obj.skeleton = cellData.skeleton;
        obj.somaNode = cellData.somaNode;

        obj.cellData = struct();
        obj.cellData.flag = false;
        obj.cellData.cellNum = [];
        obj.cellData.cellType = [];
        obj.cellData.subType = [];
        obj.cellData.annotator = [];
        obj.cellData.source = [];
        obj.cellData.onoff = [0 0]
        obj.cellData.strata = zeros(1,5);
        obj.cellData.inputs = zeros(1,3);
        obj.cellData.notes = [];

	end % constructor

	function openGUI(obj)
        % this creates the GUI and all the plots. Each plot object is
        % created then set to invisible except for soma.
		obj.fh = figure('Name', 'Cell Plot Figure',...
			'Color', 'w',...
			'DefaultUicontrolFontSize', 10,...
			'DefaultUicontrolFontName', 'Segoe UI',...
			'DefaultAxesFontName', 'Segoe UI',...
			'DefaultAxesFontSize', 10,...
			'NumberTitle', 'off',...
			'MenuBar', 'none', 'Toolbar', 'none',...
			'KeyPressFcn', @obj.onPress_key);
        %% -------------------------------------------------- menu bar ----
		mh.file = uimenu('Parent', obj.fh,...
			'Label', 'File');
		mh.sav = uimenu('Parent', mh.file,...
			'Label', 'Save cell',...
			'Callback', @obj.onMenu_saveCell);
		mh.analysis = uimenu('Parent', obj.fh,...
			'Label', 'Analysis');
		mh.reports = uimenu('Parent', obj.fh,...
			'Label', 'Reports');
		mh.unknown = uimenu('Parent', mh.reports,...
			'Label', 'Unknown synapses',...
			'Callback', @obj.onReport_unknown);
		mh.export = uimenu('Parent', obj.fh,...
			'Label', 'Export');
		mh.fig = uimenu('Parent', mh.export,...
			'Label', 'Export current figure');
		mh.csv = uimenu('Parent', mh.export,...
			'Label', 'Export as CSV');

        %% ------------------------------------------------ tab panels ----
		mainLayout = uix.HBoxFlex('Parent', obj.fh,...
			'Spacing', 5);

		obj.handles.tabLayout = uix.TabPanel('Parent', mainLayout,...
			'Padding', 5);

		cellInfoTab = uix.Panel('Parent', obj.handles.tabLayout,...
			'Padding', 5,...
			'Title', 'Cell Info');
		tabOne = uix.Panel('Parent', obj.handles.tabLayout,...
			'Padding', 5,...
			'Title', '3D plot');
		obj.handles.ax = axes('Parent', tabOne);
		tabTwo = uix.Panel('Parent', obj.handles.tabLayout,...
			'Padding', 5,...
			'Title', 'Histogram');

		obj.handles.barOne = axes('Parent', tabTwo);
		obj.handles.tabLayout.TabTitles = {'Cell Info','3D plot', 'Histogram'};
		obj.handles.tabLayout.Selection = 1;

%% create the UI panel (left) -------------------------------------
		uiLayout = uix.VBox('Parent', mainLayout,...
			'Spacing', 1, 'Padding', 5);
%% -------------------------------------------synapse setup -------
		tableData = obj.populateSynData();

		obj.handles.synTable = uitable('Parent', uiLayout);
		set(obj.handles.synTable, 'Data', tableData,...
			'ColumnName', {'Plot', 'Synapse Type', 'N', ' '},...
			'RowName', [],...
			'ColumnEditable', [true false false false],...
			'FontName', 'Segoe UI', 'FontSize', 10,...
			'CellEditCallback', @obj.onEdit_synTable);

		obj.handles.cb.addSkeleton = uicontrol('Parent', uiLayout,...
			'Style', 'checkbox',...
			'String', 'Add skeleton plot',...
			'Callback', @obj.onChanged_addSkeleton);

		obj.handles.cb.addSoma = uicontrol('Parent', uiLayout,...
			'Style', 'checkbox',...
			'String', 'Add soma',...
			'Value', 1,...
			'Callback', @obj.onSelected_addSoma);
        
%% ---------------------------------------------- bin setup -------
		somaBinLayout = uix.HBox('Parent', uiLayout,...
			'Spacing', 2);
		obj.handles.tx.somaBin = uicontrol('Parent', somaBinLayout,...
			'Style', 'edit',...
			'String', 'Bins = x');
		obj.handles.pb.binDown = uicontrol('Parent', somaBinLayout,...
			'Style', 'push',...
			'Enable', 'off',...
			'String', '<--',...
			'Callback', @obj.onSelected_binDown);
		obj.handles.pb.binUp = uicontrol('Parent', somaBinLayout,...
			'Style', 'push',...
			'String', '-->',...
			'Enable', 'off',...
			'Callback', @obj.onSelected_binUp);
		set(somaBinLayout, 'Widths', [-1.5 -1 -1]);

		% histLayout = uix.HBox('Parent', uiLayout);
		% obj.handles.lst.histType = uicontrol('Parent', histLayout,...
		% 	'Style', 'list',... 
		% 	'String', {'soma', 'z-axis', 'x-axis', 'y-axis'});
		% obj.handles.pb.histType = uicontrol('Parent', histLayout,...
		% 	'Style', 'push',...
		% 	'String', {'<html>change<br/>histogram:'},...
		% 	'Callback', @obj.onSelected_histType);
		% set(histLayout, 'Widths', [-1 -1]);
%% --------------------------------- azimuth elevation setup ------
		viewLayout = uix.HBox('Parent', uiLayout,...
			'Spacing', 10);
		azimuthLayout = uix.VBox('Parent', viewLayout);
		elevationLayout = uix.VBox('Parent', viewLayout);

		obj.handles.tx.az = uicontrol('Parent', azimuthLayout,...
			'Style', 'text',...
			'String', 'Azimuth:');
		azButtonLayout = uix.HBox('Parent', azimuthLayout,...
			'Spacing', 2);
		obj.handles.pb.azMinus = uicontrol('Parent', azButtonLayout,...
			'Style', 'push',...
			'String', '<--',...
			'Callback', @obj.onSelected_azMinus);
		obj.handles.pb.azPlus = uicontrol('Parent', azButtonLayout,...
			'Style', 'push',...
			'String', '-->',...
			'Callback', @obj.onSelected_azPlus);
		set(azButtonLayout, 'Widths', [-1 -1]);
		set(azimuthLayout, 'Heights', [-1 -1]);

		obj.handles.tx.el = uicontrol('Parent', elevationLayout,...
			'Style', 'text',...
			'String', 'Elevation:');
		elButtonLayout = uix.HBox('Parent', elevationLayout,...
			'Spacing', 2);
		obj.handles.pb.elMinus = uicontrol('Parent', elButtonLayout,...
			'Style', 'push',...
			'String', '<--',...
			'Callback', @obj.onSelected_elMinus);
		obj.handles.pb.elPlus = uicontrol('Parent', elButtonLayout,...
			'Style', 'push',...
			'String', '-->',...
			'Callback', @obj.onSelected_elPlus);
		set(elButtonLayout, 'Widths', [-1 -1]);
		set(elevationLayout, 'Heights', [-1 -1]);

		obj.handles.tx.azelInc = uicontrol('Parent', uiLayout,...
			'Style', 'text',...
			'String', '');
		obj.updateAzelDisplay();

		% initial azimuth, elevation is 2d XY plot
		obj.azel = [0 0];
		obj.azelInc = 22.5;

 		set(mainLayout, 'Widths', [-1.5 -1]);
		set(viewLayout, 'Widths', [-1 -1]);
		set(uiLayout, 'Heights', [-4 -1 -1 -1 -1 -1]);

		% graph all the synapses then set Visibile to off except soma
		obj.populatePlot();

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
			'Style', 'edit', 'String', 'c100');
		uicontrol('Parent', basicLayout,...
			'Style', 'text', 'String', 'Annotator:');
		obj.handles.ed.annotator = uicontrol('Parent', basicLayout,...
			'Style', 'edit', 'String', '');
		% 2
		cellTypeLayout = uix.VBox('Parent', infoGrid);
		uicontrol('Parent', cellTypeLayout,...
			'Style', 'text', 'String', 'Cell Type:');
		obj.handles.lst.cellType = uicontrol('Parent', cellTypeLayout,...
			'Style', 'list', 'String', CellTypes);
		set(cellTypeLayout, 'Heights', [-1 -3]);
		% 3
		uicontrol('Parent', infoGrid,...
			'Style', 'text', 'String', 'Polarity:')
		% 4
		uicontrol('Parent', infoGrid,...
			'Style', 'text', 'String', 'PR inputs:')
		% 5
		uicontrol('Parent', infoGrid,...
			'Style', 'text', 'String', 'Strata:');
		% 6
		uicontrol('Parent', infoGrid,...
			'Style', 'text', 'String', 'Notes:');
		% 7
		uicontrol('Parent', infoGrid,...
			'Style', 'text', 'String', 'No cell data detected');

		% right side
		% 1
		sourceLayout = uix.VBox('Parent', infoGrid);
		uicontrol('Parent', sourceLayout,... 
			'Style', 'text', 'String', 'Source');
		obj.handles.lst.source = uicontrol('Parent', sourceLayout,...
			'Style', 'list', 'String', {'unknown', 'Temporal', 'Inferior'});
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
		obj.handles.cb.on = uicontrol('Parent', polarityLayout,...
			'Style', 'checkbox', 'String', 'ON');
		obj.handles.cb.off = uicontrol('Parent', polarityLayout,...
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
			obj.handles = loadCellData(obj.handles, obj.cellData);
		else
			set(obj.handles.lst.cellType, 'Value', 1);
			set(obj.handles.lst.subtype, 'Enable', 'off',... 
				'String', {'Pick', 'cell type', 'first'})
		end

		% setup some final callbacks
		set(obj.handles.tabLayout, 'SelectionChangedFcn', @obj.onChanged_tab);
		% set(obj.fh, 'CloseRequestFcn', @obj.onClose_figure);
	end % openGUI

%% ------------------------------------------------ 3d plot callbacks -----
	function onPress_key(obj, ~, eventdata)
		% TODO: attach this to something else
		if obj.handles.tabLayout.Selection == 2
			switch eventdata.Character
			case 'j' % azimuth
				obj.onSelected_azMinus();
			case 'l'
				obj.onSelected_azPlus();
			case 'k' % elevation
				obj.onSelected_elMinus();
			case 'i'
				obj.onSelected_elPlus();
			case 'u' % increment
				obj.azelInc = obj.azelInc - 2.5;
				obj.updateAzelDisplay();
			case 'p'
				obj.azelInc = obj.azelInc + 2.5;
				obj.updateAzelDisplay();
			end
		end
	end
	function onEdit_synTable(obj, src,eventdata)
		tableData = src.Data;
		tableInd = eventdata.Indices;
		tof = tableData(tableInd(1), tableInd(2));
		if tof{1}
			obj.addSyn(tableInd(1));
		else
			obj.rmSyn(tableInd(1));
		end
		src.Data = tableData; % update table
	end % onEdit_synTable

    function onChanged_addSkeleton(obj,~,~)
    	if get(obj.handles.cb.addSkeleton, 'Value') == 1
    		set(obj.handles.skeletonLine, 'Visible', 'on');
	    else
	    	set(obj.handles.skeletonLine, 'Visible', 'off');
	    end
    end % addSkeleton

	function onSelected_addSoma(obj,~,~)
		if get(obj.handles.cb.addSoma, 'Value') == 1
			set(obj.handles.somaLine, 'Visible', 'on');
		else
			set(obj.handles.somaLine, 'Visible', 'off');
		end
	end % addSoma

	function onSelected_elMinus(obj,~,~)
		obj.azel(1,2) = obj.azel(1,2) - obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
	end % elMinus

	function onSelected_elPlus(obj,~,~)
		obj.azel(1,2) = obj.azel(2) + obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
	end % elPlus

	function onSelected_azMinus(obj,~,~)
		obj.azel(1,1) = obj.azel(1) - obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
	end % azMinus

	function onSelected_azPlus(obj,~,~)
		obj.azel(1,1) = obj.azel(1) + obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
	end % azPlus
%% ---------------------------------------------- histogram callbacks -----

	function onSelected_binDown(obj,~,~)
		switch obj.handles.tabLayout.Selection
		case 3
			if obj.handles.numBins.somaDist > 1
				obj.handles.numBins.somaDist = obj.handles.numBins.somaDist - 1;
				obj.deltaSomaHist();
				set(obj.handles.tx.somaBin,...
					'String', sprintf('Bins = %u', obj.handles.numBins.somaDist));
			end
		otherwise
			return;
		end
	end % onSelected_binDown

	function onSelected_binUp(obj,~,~)
		switch obj.handles.tabLayout.Selection
		case 3
			obj.handles.numBins.somaDist = obj.handles.numBins.somaDist + 1;
			obj.deltaSomaHist();
			set(obj.handles.tx.somaBin,...
				'String', sprintf('Bins = %u', obj.handles.numBins.somaDist));
		otherwise
			return;
		end
	end % onSelected_binUp

	function onChanged_tab(obj,~,~)
		set(obj.handles.pb.binUp, 'Enable', 'on');
		set(obj.handles.pb.binDown, 'Enable', 'on');
		switch obj.handles.tabLayout.Selection
			case 3
				set(obj.handles.tx.somaBin,...
					'String', sprintf('Bins = %u', obj.handles.numBins.somaDist));
			otherwise
				set(obj.handles.pb.binUp, 'Enable', 'off');
				set(obj.handles.pb.binDown, 'Enable', 'off');
		end
	end % onChanged_tab

	function onSelected_histType(obj,~,~)
		switch obj.handles.lst.histType.String{obj.handles.lst.histType.Value}
		case 'soma'
		case 'z-axis'
		case 'x-axis'
		case 'y-axis'
		end

	end
%% -------------------------------------------------- menu callbacks ------
    function onMenu_saveCell(obj,~,~)
        % this will actually create and save a new object without all the
        % figure handles and graph utils
        newNeuron = obj;
        obj.saveDir = obj.getFilepaths('save');
        newNeuron.handles = [];
        try
            obj.saveDir = uigetdir(obj.saveDir);
        catch
            fprintf('There is a problem with the saveDir in getFilepaths.m\n');
            obj.saveDir = uigetdir();
        end
    end % onMenu_saveCell

    function onReport_unknown(obj,~,~)
    	synDir = getSynNodes(obj.synData, 'unknown');
    	locID = zeros(1, length(synDir));

    	for ii = 1:length(synDir)
	    	locID(1,ii) = obj.nodeData.idMap(synDir{ii});
	    end
    	fprintf('found %u unknown synapses\n', length(locID));
	    selection = questdlg('Found %u unknown synapses. Save?', 'Save Dialog',...
	    'Yes', 'No', 'Yes');
	    switch selection
	    case 'Yes'
	    	[fname, fpath] = uiputfile();
	    	fid = fopen([fpath fname], 'w');
	    	fprintf(fid, '%u\n', locID);
	    	fclose(fid);
	    	fprintf('%u unknown synapses saved\n', length(locID));
	    case 'No'
	    	return;
	    end
    end
%% ---------------------------------------------- cellData callbacks ------
    function onSelected_getSubtypes(obj,~,~)
        cType = obj.handles.lst.cellType.String{obj.handles.lst.cellType.Value};
        if strcmp(cType, 'unknown')
            set(obj.handles.pb.subtype, 'String', 'Pick a type first!');
        else
            set(obj.handles.lst.subtype, 'String', CellSubtypes(cType),...
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
    	obj.cellData.onoff(1) = get(obj.handles.cb.on, 'Value');
    	obj.cellData.onoff(2) = get(obj.handles.cb.off, 'Value');

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
    end % onSelected_addCellData
%% ------------------------------------------------- setup functions ------
	function tableData = populateSynData(obj)
		sc = getStructureColors();
		numSyn = length(obj.synData.names);
		tableData = cell(numSyn, 4);
		for ii = 1:numSyn
			tableData{ii,1} = false;
			tableData{ii,2} = obj.synData.names{ii};
			tableData{ii,3} = obj.synData.uniqueCount(ii);
			lgnColor = rgb2hex(sc(obj.synData.names{ii}));
			tableData{ii,4} = obj.setCellColor(lgnColor, ' ');
		end
	end % populateSynData

	function populatePlot(obj)
		sc = getStructureColors();
		somaXYZ = obj.nodeData.xyzMap(obj.somaNode);
		numSyn = length(obj.synData.names);
		obj.somaDist = cell(numSyn, 1);
		% plot the synapses
		for ii = 1:numSyn
			% synapse 3d plot
			synDir = getSynNodes(obj.synData, obj.synData.names{ii});
			xyz = getDim(obj.nodeData, synDir, 'XYZ');
			obj.handles.lines(ii) = line('Parent', obj.handles.ax,...
				'XData', xyz(1,:), 'YData', xyz(2,:), 'ZData', xyz(3,:),...
				'Color', sc(obj.synData.names{ii}),...
				'Marker', '.', 'MarkerSize', 10,...
				'LineStyle', 'none');
			set(obj.handles.lines(ii), 'Visible', 'off');

			% synapse distance histograms
			obj.somaDist{ii,1} = FastEuclid3d(somaXYZ, xyz');
			[counts, bins] = histcounts(obj.somaDist{ii,1});
			binInc = bins(2) - bins(1);
			cent = bins(1:end-1) + binInc/2;
			obj.handles.somaBins(ii) = line('Parent', obj.handles.barOne,...
				'XData', cent, 'YData', counts,...
				'Color', sc(obj.synData.names{ii}),...
				'LineWidth', 2);
			set(obj.handles.somaBins(ii), 'Visible', 'off');
			xlabel(obj.handles.barOne, 'distance from soma');
			ylabel(obj.handles.barOne, 'synapse count');
			obj.handles.numBins.somaDist = length(bins);
			set(obj.handles.tx.somaBin,... 
				'String', sprintf('Bins = %u', obj.handles.numBins.somaDist));

			% [counts bins] = histcounts(xyz(:,3));
			% binInc = bins(2) - bins(1);
			% cent = bins(1:end-1) + binInc/2;
			% obj.handles.zBins(ii) = line('Parent', obj.handles.zBar,...
			% 	'XData', cent, 'YData', counts,...
			% 	'Color', sc(obj.synData.names{ii}),...
			% 	'LineWidth', 2);
			% set(obj.handles.zBins(ii), 'Visible', 'off');
			% xlabel(obj.handles.zBar, 'z-axis'); 
			% ylabel(obj.handles.zBar, 'synapse counts');
			% obj.handles.numBins.z = length(bins);
		end


		% plot the cell's skeleton
		xyz = [];
		for ii = 1:length(obj.skeleton)
	    	if ~isempty(obj.skeleton{1,ii})
	    		xyz = [xyz; obj.nodeData.xyzMap(obj.skeleton{1,ii})];
	    	end
	    end
	    obj.handles.skeletonLine = line('Parent', obj.handles.ax,...
	    	'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
	       	'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
	       	'LineStyle', 'none');
	    set(obj.handles.skeletonLine, 'Visible', 'off');

	    % plot the soma - keep it visible
	    obj.handles.somaLine = line('Parent', obj.handles.ax,...
	    	'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
	    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

	    xlabel(obj.handles.ax, 'X Coordinate');
	    ylabel(obj.handles.ax, 'Y Coordinate');
	    zlabel(obj.handles.ax, 'Z Coordinate');
	end % populatePlot

%% ------------------------------------------------- plot functions -------
	function addSyn(obj, whichSyn)
		set(obj.handles.lines(whichSyn), 'Visible', 'on');
		set(obj.handles.somaBins(whichSyn), 'Visible', 'on');
	end % addSyn

	function rmSyn(obj, whichSyn)
		set(obj.handles.lines(whichSyn), 'Visible', 'off');
		set(obj.handles.somaBins(whichSyn), 'Visible', 'off');
	end % rmSyn
    
	function deltaSomaHist(obj)
		for ii = 1:length(obj.synData.names)
			[counts, bins] = histcounts(obj.somaDist{ii,1}, obj.handles.numBins.somaDist);
			binInc = bins(2)-bins(1);
			cent = bins(1:end-1) + binInc/2;
			set(obj.handles.somaBins(ii),...
				'XData', cent, 'YData', counts);
		end
    end % deltaSomaHist
    
	function wrapAzel(obj)
		% keep azimuth,elevation between 0-360. the view() function doesn't
		% mind unwrapped values but this keeps them nice for display
		for ii = 1 : 2
			if obj.azel(1,ii) >= 360
				obj.azel(1,ii) = obj.azel(1,ii) - 360;
			elseif obj.azel(1,ii) < 0
				obj.azel(1,ii) = obj.azel(1,ii) + 360;
			end
		end
	end % wrapAzel

	function updateAzelDisplay(obj)
		set(obj.handles.tx.azelInc, 'String',...
			sprintf('Azimuth = %.1f, Elevation = %.1f, Increment = %.1f',...
			obj.azel, obj.azelInc));
	end % updateAzelDisplay
end % methods

%% ------------------------------------------------- support functions ----
methods (Static)
	function x = setCellColor(hexColor, txt)
		x = ['<html><table border=0 width=200 bgcolor=',... 
		hexColor, '><TR><TD>', txt, '</TD></TR> </table></html>'];
	end % setCellColor
end % static methods
end % classdef
