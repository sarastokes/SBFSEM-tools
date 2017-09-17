function str = getODataURL(cellNum, source, urlType)
    	% GETODATAURL   OData url based on ID number

	serverURL = getServerName();

	switch lower(source)
		case {'temporal', 't'}
			source = 'NeitzTemporalMonkey';
		case {'inferior', 'i'}
			source = 'NeitzInferiorMonkey';
		case {'rc1', 'r'}
			source = 'RC1';
	end
	
	baseURL = [serverURL source '/OData'];

	switch urlType
		case 'neuron'
			str = [baseURL '/Structures(' num2str(cellNum) ')/'];
		case 'location'
			str = [baseURL '/Locations/?$select=ID,ParentID,VolumeX,VolumeY,Z,Radius,X,Y'];
		case 'link'
			str = [baseURL '/LocationLinks/?$select=A,B'];
		case 'child'
			str = [baseURL '/Structures(' num2str(cellNum) ')/Children'];
		otherwise
			str = baseURL;
	end