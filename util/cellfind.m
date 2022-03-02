function ind = cellfind(stringsInCells, targetString)
	% CELLFIND  Like find but for strings
	% Inputs:
	%	stringsInCells 			group of strings
	%	targetString			string to search for
	% Outputs:
	%	ind 					index of target string
	%
	% History:
    %   23Dec2016 - SSP
    %   01Nov2021 - SSP - Updated to use "contains"
    % ---------------------------------------------------------------------

	assert(ischar(targetString), 'targetString = char');
	assert(iscell(stringsInCells), 'stringsInCells = cell');

	ind = find(contains(stringsInCells, targetString));	