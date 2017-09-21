function x = parseNeuronOData(neuronData, nodes, edges, childData)

	% deal with tag names
	for ii = 1:height(childData)
		if ~isempty(childData.Tags(ii,:))
			ind = strfind(childData.Tags{ii,:}, '"');
			ind = reshape(ind, 2, numel(ind)/2);
			tag = childData.Tags{ii,:};
			str = [];
			for jj = 1:size(ind,2)
				str = [str, tag(ind(1, jj)+1:ind(2,jj)-1), ' ']; %#ok<AGROW>
			end
		end
		childData.Tags{ii,:} = str(1:end-1);
	end

	% remove offedge and make it an array of locations
	offedges = nodeData.ID(nodeData.OffEdge == 1,:);
	nodeData.OffEdge = [];