function fetchChildData(ID, source)
	% FETCHCHILDDATA

	% Return IDs of all child structures
	childURL = getODataURL(cellNum, source, 'child');
	childData = readOData(childURL);
	if ~isempty(childData.value)
		childData = struct2table(childData.value);
		childData.Tags = parseTags(childData.Tags);
		IDs = childData.ID;
        fprintf('Importing data for %u child structures\n', length(IDs));

        for i = 1:length(IDs)
        	links = parseLinkData(IDs(ii));
        	if ~isempty(links)
        		edgeData = cat(1, edgeData, links);
        	end
        	nodeData = cat()

	end