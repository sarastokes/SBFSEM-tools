function endpoint = getODataURL(cellNum, source, urlType)
    	% GETODATAURL  Returns OData URL string
    	%
		% Inputs:
		%	cellNum 		Cell ID number
		%	source 			'inferior', 'temporal' ('i', 't')
		% 	urlType 		'neuron', 'location', 'link', 'child', 'scale'
		% Use:
		%	urlString = getODataURL(127, 'i', 'location')
		%

	serverURL = 'http://websvc1.connectomes.utah.edu/';

	switch lower(source)
		case {'t', 'temporal', 'neitztemporalmonkey'}
			source = 'NeitzTemporalMonkey';
		case {'i', 'inferior', 'neitzinferiormonkey'}
			source = 'NeitzInferiorMonkey';
	end
	
	baseURL = [serverURL source '/OData'];

	switch urlType
		case 'neuron'
			endpoint = [baseURL '/Structures(' num2str(cellNum) ')/'];
		case 'location'
			endpoint = [baseURL '/Structures(' num2str(cellNum), ')/Locations/'];
			%	')/Locations/?$select=ID,ParentID,VolumeX,VolumeY,Z,Radius,X,Y,Tags,OffEdge'];
		case 'link'
			endpoint = [baseURL '/Structures(' num2str(cellNum)... 
				')/LocationLinks/?$select=A,B'];
		case 'child'
			endpoint = [baseURL '/Structures(' num2str(cellNum) ')/Children',...
                '?$select=ID,TypeID,Tags,ParentID,Label'];
		case 'scale'
			endpoint = [baseURL '/Scale'];
		otherwise
			endpoint = baseURL;
	end