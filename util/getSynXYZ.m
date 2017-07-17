function xyz = getSynXYZ(dataTable, syn, micronFlag)
	% get xyz of synapse type
	% INPUTS:
	%	dataTable 		from Neuron 
	%	syn 			synapse LocalName
	% OPTIONAL:
	%	micronFlag		output in microns (default=true)
	% OUTPUTS:
	%	xyz 			location array
	%
	% 5Jul2017 - SSP - created

	if nargin < 3
		micronFlag = true;
	end

	% find unique rows with synapse name
	rows = strcmp(dataTable.LocalName, syn) & dataTable.Unique == 1;
	
	% get the xyz values for only those rows
	if micronFlag
		xyz = dataTable{rows, 'XYZum'};
	else
		xyz = dataTable{rows, 'XYZ'};
	end

