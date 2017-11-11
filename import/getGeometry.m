function ret = getGeometry(ID, source)

	source = validateSource(source);
	baseURL = [getServerName(), source, '/OData/'];

	data = readOData([baseURL,...
		'Structures(', num2str(ID), ')/',...
		'Locations?$select=TypeCode']); 

	ret = struct2array(data.value);
	ret = unique(ret);
	disp('Unique geometries: ');
	disp(ret);