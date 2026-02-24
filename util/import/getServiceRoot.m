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

	if strcmp(source, 'NeitzTemporalMonkey')
	    url = 'https://websvc.codepharm.net/NeitzTemporalMonkey/OData/';
	elseif strcmp(source, 'NeitzInferiorMonkey')
	    url = 'https://websvc.codepharm.net/NeitzInferiorMonkey/OData/';
	elseif strcmp(source, 'NeitzNasalMonkey')
	    url = 'https://websvc.codepharm.net/NeitzNM/OData/';
	elseif strcmp(source, 'NeitzCped')
	    url = 'https://websvc.codepharm.net/NeitzCPED/OData/';
	else
	    error('Unknown source: %s', source);
	end
