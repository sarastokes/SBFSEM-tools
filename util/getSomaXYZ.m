function xyz = getSomaXYZ(neuron, micronFlag)
	% get the location of soma given node uuid
	%
	% 5Jul2017 - SSP - created

	if nargin < 2
		micronFlag = true;
    else
        fprintf('working in pixels not microns\n');
	end

	% find the row matching soma node uuid
	row = strcmp(neuron.dataTable.UUID, neuron.somaNode);
	% get the XYZ values
	if micronFlag
		xyz = table2array(neuron.dataTable(row, 'XYZum'));
	else
		xyz = table2array(neuron.dataTable(row, 'XYZ'));
	end