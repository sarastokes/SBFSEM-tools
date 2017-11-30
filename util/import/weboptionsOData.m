function opts = weboptionsOData()
	% WEBOPT  OData webopts

	opts = weboptions('Timeout', 60,...
		'ContentType', 'json');