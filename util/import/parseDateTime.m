function dateString = parseDateTime(str)
	% PARSEDATETIME
	% 
	% Description:
	%	Parse DateTime string like returned from OData
	%
	% Syntax:
	%	dateString = parseDateTime(str);
	%
	% Input:
	%	str 			DateTime (char)
	% Outputs:
	%	dateString 		YYYY-MM-DD HH:mm:ss (class datetime)
	% 
	% Notes:
	% 	DateTime example: '2018-02-26T02:09:26.757-07:00'
	%
	% History:
	%	7Mar2018 - SSP
	% ------------------------------------------------------------------

    dateString = datetime(str,...
        'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX',...
        'TimeZone', 'UTC');
