function url = getServiceRoot(source)
	% GETSERVICEROOT
	%
	% Description:
	%	Get OData root
	%
	% Syntax:
	%	url = getServiceRoot(source)
	%
	% Input:
	%	source 			Volume name or abbreviation
	%
	% Output:
	%	url 			URL ending in /OData/
	%
	% See also:
	%	VALIDATESOURCE, SBFSEM.BUILTIN.VOLUMES
	%
	% History:
	%	17Dec2017 - SSP
	%	10Dec2019 - SSP - Added NasalMonkey
	%	30Jan2020 - SSP - Simplified
    % ---------------------------------------------------------------------

	source = validateSource(source);

	if strcmp(source, 'NeitzNasalMonkey')
		url = 'http://websvc1.connectomes.utah.edu/NeitzNM/OData/';
	else
		url = ['http://websvc1.connectomes.utah.edu/', source, '/OData/'];
	end