function xyz = getSomaXYZ(obj, micronFlag)
	% get the location of soma given node uuid
	%
	% 5Jul2017 - SSP - created

	if nargin < 2
		micronFlag = true;
	end

	% find the row matching soma node uuid
	row = strcmp(obj.dataTable.UUID, obj.somaNode);
	% get the XYZ values
	if micronFlag
		xyz = table2array(obj.dataTable(row, 'XYZ'));
	else
		xyz = table2array(obj.dataTable(row, 'XYZum'));
	end