sfunction adjMat = populateAdjacencyMatrix(cellNum, conData, oneDegree)
	% right now you can only get the max degrees of separation
	% in the data file provided or 1 degree

	if isempty(conData)
		fprintf('no network for adjacency matrix\n');
		return;
	end
	
	if nargin < 3
		oneDegree = false;
	else
		oneDegree = true;
	end

	if oneDegree
		% find only the contacts containing target neuron
		cellNode = find(conData.nodeTable.CellID == cellNum);
		hasNeuron = bsxfun(@eq, cellNode, conData.contacts);
		ind = find(sum(hasNeuron, 2));
		adjMat = weightedAdjacencyMatrix(conData.contacts(ind,:), conData.edgeTable.weight(ind,:));
	else
		adjMat = weightedAdjacencyMatrix(conData.contacts, conData.edgeTable.Weight);
	end
