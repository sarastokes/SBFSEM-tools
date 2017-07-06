function tableData = populateSynData(T)
	% set GUI uitable data
	% 
	% 21Jun2017 - SSP - moved from class
	% 5Jul2017 - SSP - rewrote for struct->table

	% get the synapse legend colors
	sc = getStructureColors();

	% throw out cell body and syn multi nodes
	rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
	
	% make a new table with only unique synapses
	synTable = T(rows, :);

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
		c = rgb2hex(sc(names{ii}));
		tableData{ii,4} = setCellColor(c, ' ');
		% number of histogram bins (set later)
		tableData{ii,5} = '-';
	end
