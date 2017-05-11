function nodeIDs = getSyn(cellData, syns)
  % get the nodeIDs for a specific synapse types
  % INPUT:
  %    cellData   structure from parseCellData.m
  %    synType    synapse type (string if 1, cellstr if >1)
  % OUTPUT:
  %     nodeIDs   vector if numSyns=1, cell if >1 synapse
  %
  % 6May2017 - SSP - created

  if ischar(syns)
    numSyn = 1;
  else
    numSyn = length(syns);
  end

  if numSyn > 1
    nodeIDs = cell(1, numSyn);
    for ii = 1:numSyn
      synInd = find(ismember(cellData.typeData.names, lower(syns{ii})));
      nodeIDs{ii} = cellData.typeData.uniqueNodes{synInd};
    end
  else
    synInd = find(ismember(cellData.typeData.names, lower(syns)));
    if isempty(synInd)
      warndlg('no synapse index located');
    else
      nodeIDs = cellData.typeData.uniqueNodes{synInd};
    end
  end
end
