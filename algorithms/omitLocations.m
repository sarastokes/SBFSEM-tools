function locIDs = omitLocations(cellID, source)
	% OMITLOCATIONS
	%
	% Description:
	%	Searches for any omitted location IDs associated with a cell ID
	%
	% Syntax:
	%	locIDs = omitLocations(437, 'r');
	% 
	% Inputs:
	%	cellID 			Viking Structure ID number
	%	source 			Volume name or abbreviation
	%
	% Output:
	%	locIDs 			Location IDs to omit
	%
	% Note:
	%	This function searches for the OMITTED_IDS_ files in the data 
	%	directory. Add to the file by creating a new line, then adding
	%	the cell ID and location ID, separated by a comma.
	%
	% History:
	%	16Feb2018 - SSP
	%-------------------------------------------------------------------

	assert(isnumeric(cellID), 'Cell ID must be a number');
	source = validateSource(source);

	dataDir = [fileparts(fileparts(mfilename('fullpath'))), '\data\'];

    try
    	data = dlmread([dataDir, 'OMITTED_IDS_', upper(source), '.txt']);
    catch
        data = [];
    end
	if isempty(data)
		locIDs = [];
	else
		cellMatches = data(:, 1) == cellID;
		locIDs = data(cellMatches, 2);
	end