function nodeInd = getNodeName(cellData, nodeInd)
	% nodeInd --> nodeName
	% currently not using but left in. 
	% helpful for working with raw data struct
	%
	% SSP - 7May2017 - created


	nodeInd = find(ismember(cellData.nodeList, nodeName));
