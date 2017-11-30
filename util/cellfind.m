function ind = cellfind(stringsInCells, targetString)
	% CELLFIND  Like find but for strings
	% Inputs:
	%	stringsInCells 			group of strings
	%	targetString			string to search for
	% Outputs:
	%	ind 					index of target string
	%
	% 23Dec2016 - SSP

	assert(ischar(targetString), 'targetString = char');
	assert(iscell(stringsInCells), 'stringsInCells = cell');

	ind = find(not(cellfun('isempty', strfind(stringsInCells, targetString))));	