function xyz = getSomaXYZ(obj)
	% get the location of soma given node uuid
	%
	% 5Jul2017 - SSP - created

	% find the row matching soma node uuid
	row = strcmp(obj.dataTable.UUID, obj.somaNode);
	% get the XYZ values
	xyz = table2array(obj.dataTable(row, 'XYZ'));