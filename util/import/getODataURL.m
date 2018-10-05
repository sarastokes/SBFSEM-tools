function endpoint = getODataURL(ID, source, urlType)
	% GETODATAURL  Returns OData URL string
	%
	% Inputs:
	%	ID              Unique ID number
	%	source 			'inferior', 'temporal' ('i', 't')
	% 	urlType 		'neuron', 'location', 'link', 'child', 'scale'
	% Use:
	%	urlString = getODataURL(127, 'i', 'location')
	%

		
	baseURL = getServiceRoot(source);

	switch urlType
		case 'neuron'
			endpoint = [baseURL 'Structures(' num2str(ID) ')/'];
		case 'location'
			endpoint = [baseURL 'Structures(' num2str(ID), ')/Locations/'];
		case 'link'
			endpoint = [baseURL 'Structures(' num2str(ID)... 
				')/LocationLinks/?$select=A,B'];
		case 'child'
			endpoint = [baseURL 'Structures(' num2str(ID) ')/Children',...
                '?$select=ID,TypeID,Tags,ParentID,Label'];
		case 'scale'
			endpoint = [baseURL 'Scale'];
		otherwise
			endpoint = baseURL;
	end