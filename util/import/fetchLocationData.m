function Locs = fetchLocationData(ID, source)

	locationURL = getODataURL(ID, source, 'location');
	importedData = readOData(locationURL);
	if ~isempty(importedData.value)
		Locs = parseLocationData(importedData.value);
    else
    	Locs = [];
    	% This is important to track bc throws errors in VikingPlot
    	fprintf('No locations for s%u\n', ID);
    end
