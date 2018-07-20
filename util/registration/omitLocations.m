function locIDs = omitLocations(cellID, source)
	% OMITLOCATIONS
	%
	% Description:
	%	Searches for any omitted location IDs associated with a cell ID
	%
	% Syntax:
	%	locIDs = omitLocations(cellID, source);
	% 
	% Inputs:
	%	cellID 			Viking Structure ID number
	%	source 			Volume name or abbreviation
	%
	% Output:
	%	locIDs 			Location IDs to omit
    %
    % Example:
    %   locIDs = omitLocations(437, 'r');
	%
	% Note:
	%	This function searches for the OMITTED_IDS_ files in the data 
	%	directory. Add to the file by creating a new line, then adding
	%	the cell ID and location ID, separated by a comma.
    %   See data\OMITTED_IDS_RC1.txt for an example.
	%
	% History:
	%	16Feb2018 - SSP
    %   13Mar2018 - SSP - Added check for whether omitted IDs file exists
    %	11Jul2018 - SSP - Speeded up
	% ---------------------------------------------------------------------

	assert(isnumeric(cellID), 'Cell ID must be a number');
	source = validateSource(source);
	source = upper(source);

	dataFile = [fileparts(fileparts(fileparts(mfilename('fullpath')))),...
        filesep, 'data', filesep, 'OMITTED_IDS_', source, '.txt'];

    if exist(dataFile, 'file')
    	data = dlmread(dataFile);
        cellMatches = data(:, 1) == cellID;
		locIDs = data(cellMatches, 2);
    else
        % Volume doesn't have omitted IDs file
        locIDs = [];
    end