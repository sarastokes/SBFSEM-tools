function data = readOData(endpoint)
	% READODATA  Webread with options
	% Inputs:
	%	endpoint 	sql query url
	% Use:
	%	data = readOData(getODataURL(127, 'i', 'location'));
	%
	% Note: for some reason this always times out the first time
	% 	it is used in a matlab window. Just run it again...	
	
    data = webread(endpoint,...
        weboptionsOData);