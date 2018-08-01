function Z = omitSections(source)
	% OMITSECTIONS
	%
	% Description:
	%	Return sections to omit, by volume name
	%
	% Syntax:
	%	Z = omitSections(source)
	%
	% Input:
	%	source 		Volume name or abbreviation
	%
	% Output:
	%	Z 			Section number(s)
	%
	% Note:
	%	Z will be empty if the volume doesn't have an omitted section file
	%	See data/OMITTED_SECTIONS_NEITZINFERIORMONKEY.txt for an example.
	%
	% History:
	%	11Jul2018 - SSP
	% --------------------------------------------------------------------

	source = validateSource(source);
	source = upper(source);

	dataFile = [fileparts(fileparts(fileparts(mfilename('fullpath')))),...
		filesep, 'data', filesep, 'OMITTED_SECTIONS_', source, '.txt'];
    disp(dataFile)

	if exist(dataFile, 'file')
		Z = dlmread(dataFile);
	else
		Z = [];
	end
