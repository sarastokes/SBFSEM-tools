function opts = getODataOptions()
	% GETODATAOPTIONS
    %
    % Description
    %   weboptions used for OData queries
    %
    % History:
    %   5Mar2018 - SSP - changed from webooptionsOData.m
    % --------------------------------------------------------------

	opts = weboptions('Timeout', 60,...
		'ContentType', 'json',...
        'ContentReader', @loadjson);