function xyz = getSynXYZ(dataTable, syn)
	% get xyz of synapse type
	% INPUTS:
	%	dataTable 		from Neuron 
	%	syn 			synapse LocalName
	% OUTPUTS:
	%	xyz 			location array
	%
	% 5Jul2017 - SSP - created

	% find unique rows with synapse name
	rows = strcmp(dataTable.LocalName, syn) & dataTable.Unique == 1;
	
	% get the xyz values for only those rows
	xyz = dataTable{rows, 'XYZ'};

