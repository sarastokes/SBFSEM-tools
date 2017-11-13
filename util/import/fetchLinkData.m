function LocLinks = fetchLinkData(ID, source)
	% FETCHLINKDATA

	linkURL = getODataURL(ID, source, 'link');
	importedData = readOData(linkURL);
	if ~isempty(importedData.value)
		LocLinks = zeros(size(importedData.value, 1), 3);
		LocLinks(:, 1) = repmat(ID, [size(importedData, 1), 1]);
		LocLinks(:, 2) = vertcat(importedData.value.A);
		LocLinks(:, 3) = vertcat(importedData.value.B);
	else
		LocLinks = [];
	end