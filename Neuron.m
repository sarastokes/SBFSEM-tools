classdef Neuron < handle
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
	connectivityDate % date added connectivity
	conData % connectivity data
end

properties
	fh
	handles
	azel = [0 90]% current azimuth + elevation view
	azelInc = 22.5
	somaDist
end

methods
	function obj = Neuron(cellData, cellNum)

		obj.json2Neuron(cellData);
		if nargin < 2
	    answer = inputdlg('Input the cell number:',... 
  	  	'Cell number dialog box', 1);
	    cellNum = answer{1};
	  end

    obj.cellData = struct();
    obj.cellData.flag = false;
    obj.cellData.cellNum = cellNum;
    obj.cellData.cellType = [];
    obj.cellData.subType = [];
    obj.cellData.annotator = [];
    obj.cellData.source = [];
    obj.cellData.onoff = [0 0];
    obj.cellData.strata = zeros(1,5);
    obj.cellData.inputs = zeros(1,3);
    obj.cellData.notes = [];
	end % constructor

  function updateData(obj, dataFile)
  	obj.json2Neuron(dataFile)
  	fprintf('updated underlying data\n');
  end % update data

	function json2Neuron(obj, cellData)
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
  end % json2neuron

	function addConnectivity(obj, connectivityFile)
		if ischar(connectivityFile)
			obj.conData = parseConnectivity(connectivityFile);
		elseif isstruct(connectivityFile)
			obj.conData = connectivityFile;
		end
	end % addConnectivity

%------------------------------------------------------------------
%% -------------------------------------------------- GUI setup ---
%------------------------------------------------------------------

	function openGUI(obj)
    % this creates the GUI and all the plots. Each plot object is
    % created then set to invisible except for soma.
		obj.fh = figure(...
			'Name', sprintf('Cell %u',num2str(obj.cellData.cellNum)),...
			'Color', 'w',...
			'DefaultUicontrolFontName', 'Segoe UI',...
			'DefaultUicontrolFontSize', 10,...
			'DefaultAxesFontName', 'Segoe UI',...
			'DefaultAxesFontSize', 10,...
			'NumberTitle', 'off',...
			'MenuBar', 'none',... 
			'Toolbar', 'none');

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
		mh.overview = uimenu('Parent', obj.fh,...
			'Label', 'Synapse Overview',...
			'Callback', @obj.onReport_synapseOverview);
		mh.unknown = uimenu('Parent', mh.reports,...
			'Label', 'Unknown synapses',...
			'Callback', @obj.onReport_unknown);
        mh.incomplete = uimenu('Parent', mh.reports,...
            'Label', 'Incomplete branches',...
            'Callback', @obj.onReport_incomplete);
		mh.export = uimenu('Parent', obj.fh,...
			'Label', 'Export');
		mh.fig = uimenu('Parent', mh.export,...
			'Label', 'Export current figure',...
			'Callback', @obj.onMenu_exportFig);
		mh.csv = uimenu('Parent', mh.export,...
			'Label', 'Export as CSV');

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
		obj.handles.tabLayout.TabTitles = {'Cell Info','3D plot', 'Histograms', 'Connectivity', 'Renders'};
		obj.handles.histTabs.TabTitles = {'Soma', 'Z-axis'};
		obj.handles.tabLayout.Selection = 1;
		obj.handles.histTabs.Selection = 1;

%% create the UI panel (left) -------------------------------------
		uiLayout = uix.VBox('Parent', mainLayout,...
			'Spacing', 1, 'Padding', 5);
%% -------------------------------------------synapse setup -------
		tableData = populateSynData(obj.synData);

		obj.handles.synTable = uitable('Parent', uiLayout);
		set(obj.handles.synTable, 'Data', tableData,...
			'ColumnName', {'Plot', 'Synapse Type', 'N', ' ', 'Bins'},...
			'RowName', [],...
			'ColumnEditable', [true false false false true],...
			'ColumnWidth', {35, 'auto', 40, 25, 30},...
			'FontName', 'Segoe UI', 'FontSize', 10,...
			'CellEditCallback', @obj.onEdit_synTable);

%% ---------------------------------------------- 3d plot setup ----
		obj.handles.cb.addSkeleton = uicontrol('Parent', uiLayout,...
			'Style', 'checkbox', 'Visible', 'off',...
			'String', 'Add skeleton plot',...
			'Callback', @obj.onChanged_addSkeleton);

		obj.handles.cb.addSoma = uicontrol('Parent', uiLayout,...
			'Style', 'checkbox',...
			'String', 'Add soma',...
			'Value', 1, 'Visible', 'off',...
			'Callback', @obj.onSelected_addSoma);

		obj.handles.cb.showCon = uicontrol('Parent', uiLayout,...
			'Style', 'checkbox',...
			'String', 'Show connectivity',...
			'Value', 0, 'Visible', 'off',...
			'Callback', @obj.onSelected_showConnectivity);

		obj.handles.tx.azelInc = uicontrol('Parent', uiLayout,...
			'Style', 'text',...
			'String', '');
		obj.handles.tx.enableKeys = uicontrol('Parent', uiLayout,...
			'Style', 'text', 'String', 'Click here to enable arrow keys',...
			'KeyPressFcn', @obj.onPress_key);
		obj.updateAzelDisplay();

 		set(mainLayout, 'Widths', [-1.5 -1]);
		% set(viewLayout, 'Widths', [-1 -1]);
		set(uiLayout, 'Heights', [-4 -1 -1 -1 -1]);

		% graph all the synapses then set Visibile to off except soma
		obj = populatePlots(obj);
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
			'Style', 'list', 'String', CellTypes);
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
%% ------------------------------------------------ render callbacks -----
	function onSelected_showRender(obj,~,~)
		imName = obj.handles.lst.renders.String{obj.handles.lst.renders.Value};
        imName = [getFilepaths('render') imName];
		im = imread(imName);
		imshow(im(:,:,1:3), 'Parent', obj.handles.ax.render,... 
			'InitialMagnification', 'fit');
	end % onSelected_showRender
%% ------------------------------------------------ 3d plot callbacks -----
	function onPress_key(obj, ~, eventdata)
		% TODO: attach this to something else
		if obj.handles.tabLayout.Selection == 2
			switch eventdata.Character
			case 'j' % azimuth
				obj.azel = setAzimuth(obj.azel, obj.azelInc, 'down');
			case 'l'
				obj.azel = setAzimuth(obj.azel, obj.azelInc, 'up');
			case 'k' % elevation
				obj.azel = setElevation(obj.azel, obj.azelInc, 'down');
			case 'i'
				obj.azel = setElevation(obj.azel, obj.azelInc, 'up');
			case 'u' % increment
				obj.azelInc = obj.azelInc - 2.5;
			case 'p'
				obj.azelInc = obj.azelInc + 2.5;
			end
			obj.wrapAzel();
			obj.updateAzelDisplay();
			view(obj.handles.ax.d3plot, obj.azel);
		end
	end % onPress_key

	function onEdit_synTable(obj, src,eventdata)
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
    else
    	set(obj.handles.skeletonLine, 'Visible', 'off');
    end
  end % onSelected_addSkeleton

	function onSelected_addSoma(obj,~,~)
		if get(obj.handles.cb.addSoma, 'Value') == 1
			set(obj.handles.somaLine, 'Visible', 'on');
		else
			set(obj.handles.somaLine, 'Visible', 'off');
		end
	end % onSelected_addSoma

	function onSelected_showConnectivity(obj,~,~)
	end % onSelected_showConnectivity

%% ---------------------------------------------- histogram callbacks -----
	function onChanged_tab(obj,~,~)
		set(obj.handles.cb.addSoma, 'Visible', 'off');
		set(obj.handles.cb.addSkeleton, 'Visible', 'off');
          set(obj.handles.tx.azelInc, 'Visible', 'off');
		set(obj.handles.tx.enableKeys,...
			'Visible', 'off');
		set(obj.handles.cb.showCon, 'Visible', 'off');
		switch obj.handles.tabLayout.Selection
		case 1 
		case 2
			set(obj.handles.tx.enableKeys,... 
				'Visible', 'on',...
				'String', 'Click here to enable arrow keys');
            set(obj.handles.tx.azelInc, 'Visible', 'on');
			set(obj.handles.cb.addSoma, 'Visible', 'on');
			set(obj.handles.cb.addSkeleton, 'Visible', 'on');
			set(obj.handles.cb.showCon, 'Visible', 'on');
		case 3
			set(obj.handles.tx.enableKeys,...
				'Visible', 'on',...
				'String', 'Edit bin numbers in table');
		end
	end % onChanged_tab

	function onChanged_histTab(obj,~,~)
		switch obj.handles.histTabs.Selection
		case 1 % soma plot
			for ii = 1:length(obj.synData.names)
				obj.handles.synTable.Data{ii,5} = obj.handles.numBins(1,ii);
			end
		case 2 % z-axis plot
			for ii = 1:length(obj.synData.names)
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
	        obj.saveDir = getFilepaths('save');
	        newNeuron.handles = [];
	        newNeuron.fh = [];
	        uisave('newNeuron', sprintf('c%u.mat', obj.cellData.cellNum));
	        fprintf('Saved!\n');
	        delete(gcf);
	      case 'No'
	      	return;
	      end
    end % onMenu_saveCell

    function onMenu_exportFig(obj,~,~)
    	% get the current axis handle
    	switch obj.handles.tabLayout.Selection
    	case 1
    		warndlg('Need an active figure!');
    		return;
    	case 2
    		axHandle = obj.handles.ax.d3plot;
    	case 3
    		axHandle = obj.handles.ax.soma;
    	end
    	fig = figure('Color', 'w');
    	hh = copyobj(axHandle, fig);
    	set(hh, 'Position', get(0, 'DefaultAxesPosition'));
    end % onMenu_exportFig

    function onReport_unknown(obj,~,~)
    	synDir = getSynNodes(obj.synData, 'unknown');
    	locID = zeros(1, length(synDir));

    	for ii = 1:length(synDir)
	    	locID(1,ii) = obj.nodeData.idMap(synDir{ii});
	    end
    	fprintf('found %u unknown synapses\n', length(locID));
	    selection = questdlg(...
	    	sprintf('Save %u unknown synapses?', length(locID)),... 
	    	'Save Dialog',...
	    'Yes', 'No', 'Yes');
	    switch selection
	    case 'Yes'
	    	if isempty(obj.cellData.cellNum)
	    		warndlg('Set cell number first!');
	    		fprintf('no cell number found, no save\n');
	    		return;
	    	else 
	    		fid = fopen(sprintf('c%u unknown.txt', obj.cellData.cellNum), 'w');
	    		fprintf(fid, '%u \n', locID);
	    		fclose(fid);
	    		fprintf('%u unknown synapses saved\n', length(locID));
	    	end
	    case 'No'
	    	return;
	    end
    end % onReport_unknown
    
    function onReport_incomplete(obj,~,~)
        % get the OffEdge nodes
    end % onReport_incomplete

    function onReport_synapseOverview(obj,~,~)
    	selection = questdlg('Save synapse overview?',...
    		'Save dialog',...
    		'Yes', 'No', 'Yes');
    	switch selection 
	    case 'Yes'
	    	fid = fopen(sprintf('c%u_overview.txt', obj.cellData.cellNum), 'w');
	    	fprintf(fid, 'c%u Synapses:\n', obj.cellData.cellNum);
	    	for ii = 1:length(obj.synData.names)
	    		fprintf(fid, '%u - %s\n', obj.synData.uniqueCount(ii), obj.synData.names{ii});
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
%% ------------------------------------------------- setup functions ------
	% \ui\populatePlots
	% \ui\populateSynData
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
			synInd = 1:length(obj.synData.names);
		end
		switch obj.handles.histTabs.Selection
		case 1
			for ii = 1:length(synInd)
				[counts, binCenters] = obj.getHist(obj.somaDist{synInd(ii), 1}, obj.handles.synTable.Data{synInd(ii),5});
				set(obj.handles.somaBins(synInd(ii)),...
					'XData', binCenters, 'YData', counts);
			end
		case 2
			for ii = 1:length(synInd)
				synDir = getSynNodes(obj.synData, obj.synData.names{ii});
				z = getDim(obj.nodeData, synDir, 'Z');
				[counts, binCenters] = obj.getHist(z, obj.handles.synTable.Data{ii,1});
				set(obj.handles.zBins(ii), 'XData', counts, 'YData', binCenters);
			end
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

end % static methods
end % classdef
