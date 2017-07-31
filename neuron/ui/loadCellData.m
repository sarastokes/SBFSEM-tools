function [handles,titlestr] = loadCellData(handles, cellData)
	% loads cell data into GUI


	handles.ed.cellNum.String = num2str(cellData.cellNum);
	titlestr = handles.ed.cellNum.String;
	handles.ed.annotator.String = cellData.annotator;
	set(handles.lst.source, 'Value', find(ismember(handles.lst.source.String, cellData.source)));
	if ~isempty(cellData.cellType)
		set(handles.lst.cellType, 'Value', find(ismember(handles.lst.cellType.String, cellData.cellType)));
		% call subtypes
		if ~strcmp(cellData.cellType, 'unknown')
			set(handles.lst.subtype, 'String', CellSubtypes(cellData.cellType),...
				'Enable', 'on');
			if ~isempty(cellData.subType)
				set(handles.lst.subtype, 'Value', find(ismember(handles.lst.subtype.String, cellData.subType)));
				titlestr = [titlestr ' ' cellData.subType];
			end
		end
		titlestr = [titlestr ' ' cellData.cellType];
	end


	handles.cb.onPol.Value = cellData.onoff(1);
	handles.cb.offPol.Value = cellData.onoff(2);

	strata = 1:5;
	for ii = 1:5
		handles.cb.(sprintf('s%u', ii)).Value = cellData.strata(1,ii);
	end

	inputTypes = {'lmcone', 'scone', 'rod'};
	for ii = 1:length(inputTypes)
		handles.cb.(inputTypes{ii}).Value = cellData.inputs(ii);
	end

	handles.ed.notes.String = cellData.notes;




