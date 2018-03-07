function data = readOData(endpoint)
	% READODATA  
    %
    % Description:
    %   Webread with OData-specific options
    %
    % Syntax:
	%	data = readOData(getODataURL(127, 'i', 'location'));
    %
	% Inputs:
	%	endpoint 	OData query url
    % Outputs:
    %   data        Information returned from webread()
	%
    % History:
    %   13Nov2017 - SSP
    %   5Mar2018 - SSP - Added getODataOptions function
    % ---------------------------------------------------------------------
	
    data = webread(endpoint, getODataOptions());