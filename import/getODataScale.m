function scale = getODataScale(source)
	% GETODATASCALE  Get volume scaling 
	%
	% 1Oct2017 - SSP - modified from VikingPlot

	endpoint = getODataURL([], source, 'scale');
	scale = webread(endpoint,... 
		'Timeout', 30,...
		'ContentType', 'json');