function tableData = populateSynData(synData)
	% set GUI uitable data
	% 
	% 21Jun2017 - SSP - moved from class

	sc = getStructureColors();
	numSyn = length(synData.names);
	tableData = cell(numSyn, 5);

	for ii = 1:numSyn
		tableData{ii,1} = false;
		tableData{ii,2} = synData.names{ii};
		tableData{ii,3} = synData.uniqueCount(ii);
		c = rgb2hex(sc(synData.names{ii}));
		tableData{ii,4} = setCellColor(c, ' ');
		tableData{ii,5} = '-';
	end