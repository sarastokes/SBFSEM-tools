classdef NeuronNodes < handle
	% Analysis and graphs based only on nodes, without edges

properties
	% nodeData consists of containers.Map bins for each property (the
	% columns in Tulip). The properties included are: LocationInViking,
	% LocationID, ParentID, StructureType, Tags, ViewSize, OffEdge and
	% Terminal. See parseNodes.m for more details
	nodeData
	% this contains data about each synapse type in the cell
    synData
    tulipData % currently not using, might get rid of
    cellData % user defined properties that can't be automated
    
    nodeList % all nodes
    skeleton % just the "cell" nodes
    somaNode % largest "cell" node
    
    fname
    saveDir
	parseDate % date run through parseNodesEdges.m

end

properties
	fh
	handles
	azel % current azimuth + elevation view
	azelInc
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
        
        obj.nodeList = cellData.nodeList;
        
        obj.synData = cellData.typeData;
        obj.tulipData = cellData.tulipData;
        obj.nodeData = cellData.props;

        obj.skeleton = cellData.skeleton;
        obj.somaNode = cellData.somaNode;

        obj.saveDir = [];   

        obj.cellData = struct();
        obj.cellData.cellNum = [];
        obj.cellData.cellType = [];
        obj.cellData.user = [];
        obj.cellData.source = [];

	end % constructor

	function openGUI(obj)

		obj.fh = figure('Name', 'Cell Plot Figure',...
			'Color', 'w',...
			'DefaultUicontrolFontSize', 10,...
			'DefaultUicontrolFontName', 'Segoe UI',...
			'DefaultAxesFontName', 'Segoe UI',...
			'DefaultAxesFontSize', 10,...
			'KeyPressFcn', @obj.onPress_key);

		mainLayout = uix.HBoxFlex('Parent', obj.fh,...
			'Spacing', 5);

		plotLayout = uix.VBox('Parent', mainLayout,...
			'Spacing', 5);

		uiLayout = uix.VBox('Parent', mainLayout,...
			'Spacing', 1, 'Padding', 5);
        
		obj.handles.ax = axes('Parent', plotLayout);

		% obj.handles.tx.synList = uicontrol('Parent', uiLayout,...
		% 	'Style', 'text',...
		% 	'String', 'Synapses found: ');

		tableData = obj.populateSynData();

		obj.handles.synTable = uitable('Parent', uiLayout);
		set(obj.handles.synTable, 'Data', tableData,...
			'ColumnName', {'Plot', 'Synapse', 'Number'},...
			'RowName', [],...
			'ColumnEditable', true(1,3),...
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
		set(uiLayout, 'Heights', [-4 -1 -1 -1 -1]);

		% graph all the synapses then set Visibile to off
		obj.populatePlot();
	end % openGUI

%% ------------------------------------------------- callbacks ------------
	function onPress_key(obj, ~, eventdata)
		switch eventdata.Character
		case 'j' % azimuth
			obj.onSelected_azMinus();
		case 'l'
			obj.onSelected_azPlus();
		case 'k'
			obj.onSelected_elMinus();
		case 'i'
			obj.onSelected_elPlus();
		case 'u'
			obj.azelInc = obj.azelInc - 2.5;
			obj.updateAzelDisplay();
		case 'p'
			obj.azelInc = obj.azelInc + 2.5;
			obj.updateAzelDisplay();
		end
	end
	function onEdit_synTable(obj, src,eventdata)
		fprintf('cell edit callback!\n');
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
		% set(obj.handles.tx.el, 'String', sprintf('Elevation = %u', obj.azel(1,2)));
	end % elMinus

	function onSelected_elPlus(obj,~,~)
		obj.azel(1,2) = obj.azel(2) + obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
		% set(obj.handles.tx.el, 'String', sprintf('Elevation = %u', obj.azel(1,2)));
	end % elPlus

	function onSelected_azMinus(obj,~,~)
		obj.azel(1,1) = obj.azel(1) - obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
		% set(obj.handles.tx.az, 'String', sprintf('Elevation = %u', obj.azel(1,1)));
	end % azMinus

	function onSelected_azPlus(obj,~,~)
		obj.azel(1,1) = obj.azel(1) + obj.azelInc;
		obj.wrapAzel();
		view(obj.handles.ax, obj.azel);
        obj.updateAzelDisplay();
		% set(obj.handles.tx.el, 'String', sprintf('Elevation = %u', obj.azel(1,1)));
	end % azPlus

%% ------------------------------------------------- setup functions ------
	function tableData = populateSynData(obj)
		numSyn = length(obj.synData.names);
		tableData = cell(numSyn, 3);
		for ii = 1:numSyn
			tableData{ii,1} = false;
			tableData{ii,2} = obj.synData.names{ii};
			tableData{ii,3} = obj.synData.uniqueCount(ii);
		end
	end % populateSynData

	function populatePlot(obj)
		sc = getStructureColors();
		numSyn = length(obj.synData.names);
		% plot the synapses
		for ii = 1:numSyn
			synDir = getSynNodes(obj.synData, obj.synData.names{ii});
			xyz = getDim(obj.nodeData, synDir, 'XYZ');
			obj.handles.lines(ii) = line('Parent', obj.handles.ax,...
				'XData', xyz(1,:), 'YData', xyz(2,:), 'ZData', xyz(3,:),...
				'Color', sc(obj.synData.names{ii}),...
				'Marker', '.', 'MarkerSize', 10,...
				'LineStyle', 'none');
			set(obj.handles.lines(ii), 'Visible', 'off');
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

	    % plot the soma
	    xyz = obj.nodeData.xyzMap(obj.somaNode);
	    obj.handles.somaLine = line('Parent', obj.handles.ax,...
	    	'XData', xyz(1), 'YData', xyz(2), 'ZData', xyz(3),...
	    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

	    xlabel(obj.handles.ax, 'X Coordinate');
	    ylabel(obj.handles.ax, 'Y Coordinate');
	    zlabel(obj.handles.ax, 'Z Coordinate');
	end % populatePlot

	function addSyn(obj, whichSyn)
		set(obj.handles.lines(whichSyn), 'Visible', 'on');
	end % addSyn

	function rmSyn(obj, whichSyn)
		set(obj.handles.lines(whichSyn), 'Visible', 'off');
	end % rmSyn

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
methods
	function distFromSoma = fastEuclid3(somaXYZ, synXYZ)
        % I think this is the fastest but might update later
		somaXYZ = repmat(somaXYZ, [size(synXYZ,1) 1]);
		x = bsxfun(@minus, somaXYZ(:,1), synXYZ(:,1)');
		y = bsxfun(@minus, somaXYZ(:,2), synXYZ(:,2)');
		z = bsxfun(@minus, somaXYZ(:,3), synXYZ(:,3)');
		distFromSoma = sqrt(x.^2 + y.^2 + z.^2);		
	end % fastEuclid3
end % methods
end % classdef
	