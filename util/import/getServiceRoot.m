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

	if strcmp(source, ‘NeitzTemporalMonkey’)
	    url = ‘http://vpn.codepharm.net/NeitzTemporalMonkey/OData/’;
	elseif strcmp(source, ‘NeitzInferiorMonkey’)
	    url = ‘http://vpn.codepharm.net/NeitzInferiorMonkey/OData/’;
	elseif strcmp(source, ‘NeitzNasalMonkey’)
	    url = ‘http://vpn.codepharm.net/NeitzNM/OData/’;
	elseif strcmp(source, ‘NeitzCped’)
	    url = ‘http://vpn.codepharm.net/NeitzCPED/OData/’;
	else
	    error(‘Unknown source: %s’, source);
	end

	%if strcmp(source, 'NeitzNasalMonkey')        
	%	url = 'http://websvc1.connectomes.utah.edu/NeitzNM/OData/';
	%else
	%	url = ['http://websvc1.connectomes.utah.edu/', source, '/OData/'];
	%end
