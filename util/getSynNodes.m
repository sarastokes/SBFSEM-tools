function nodeNames = getSynNodes(cellData, syns)
	% get the nodeIDs for specific synapse types
  % INPUT:
  %    cellData   structure from parseNodesEdges.m or obj.typeData
  %    synType    synapse type (string if 1, cellstr if >1)
  % OUTPUT:
  %     nodeIDs   vector if numSyns=1, cell if >1 synapse
  %
  % 6May2017 - SSP - created
  % 7May2017 - SSP - added structure tags
  % 16Jun2017 - SSP - ready.. updated to map structure

  if isfield(cellData, 'typeData')
      cellData = cellData.typeData;
  end
  
  % one or >1 synapses
  if ischar(syns)
  	numSyn = 1;
  else
  	numSyn = length(syns);
  end

  if numSyn > 1
      nodeNames = cell(numSyn, 1);
    for ii = 1:numSyn
      currentSyn = lower(syns{ii});
      synInd = find(ismember(cellData.names, lower(currentSyn)));
      if isempty(synInd)
          error('Synapse %s is not in typeData.names', syns);
      end
      nodeNames{ii,1} = cellData.uniqueNodes{synInd};
    end
  else
    currentSyn = lower(syns);
    synInd = find(ismember(cellData.names, lower(currentSyn)));
    if isempty(synInd)
        error('Synapse %s is not in typeData.names', syns);
    end
    nodeNames = cellData.uniqueNodes{synInd};
  end