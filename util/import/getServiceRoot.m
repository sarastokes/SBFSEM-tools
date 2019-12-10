function url = getServiceRoot(source)

	source = validateSource(source);

	switch source
		case 'NeitzInferiorMonkey'
			url = 'http://websvc1.connectomes.utah.edu/NeitzInferiorMonkey/OData/';
        case 'NeitzNasalMonkey'
            url = 'http://websvc1.connectomes.utah.edu/NeitzNM/OData/';
		case 'NeitzTemporalMonkey'
			url = 'http://websvc1.connectomes.utah.edu/NeitzTemporalMonkey/OData/';
		case 'RC1'
			url = 'http://websvc1.connectomes.utah.edu/RC1/OData/';
	end