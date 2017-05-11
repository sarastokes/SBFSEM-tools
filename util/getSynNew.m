function nodeIDs = getSynNew(cellData, syns)
  % get the nodeIDs for a specific synapse types
  % INPUT:
  %    cellData   structure from parseCellData.m
  %    synType    synapse type (string if 1, cellstr if >1)
  % OUTPUT:
  %     nodeIDs   vector if numSyns=1, cell if >1 synapse
  %
  % 6May2017 - SSP - created
  % 7May2017 - SSP - added structure tags

  if ischar(syns)
    numSyn = 1;
  else
    numSyn = length(syns);
  end

  if numSyn > 1
    nodeIDs = cell(1, numSyn);
    for ii = 1:numSyn
      currentSyn = lower(syns{ii});
      if ~strfind(syns{ii}, 'postsynapse') && length(syns{ii}) > length('postsynapse')
        [tagIDs, currentSyn] = getTagInd(currentSyn);
      end
      synInd = find(ismember(cellData.typeData.names, lower(syns{ii})));
      nodeIDs{ii} = cellData.typeData.uniqueNodes{synInd};
      if exist('tagIDs', 'var')
        nodeIDs{ii} = intersect(nodeIDs{ii}, tagIDs);
      end
    end
  else
    if isempty(synInd)
      error('no synapse index located');
    else
      currentSyn = lower(syns);
      if ~strfind(syns, 'postsynapse') && length(syns) > length('postsynapse')
        [tagIDs, currentSyn] = getTagInd(currentSyn);
      end
      synInd = find(ismember(cellData.typeData.names, currentSyn));
      nodeIDs = cellData.typeData.uniqueNodes{synInd};
      if exist('tagIDs', 'var')
        nodeIDs = intersect(nodeIDs, tagIDs);
      end
    end
  end

  function [tagIDs, currentSyn] = getTagInd(currentSyn)
    synTag = currentSyn(length('postsynapse')+1:end)
    synTag = getFullTag(synTag);
    currentSyn = 'postsynapse';
    tagInd = find(ismember(cellData.typeData.structureTags, lower(synTag)));
    tagIDs = cellData.typeData.uniqueNodes{tagInd};
  end

end
