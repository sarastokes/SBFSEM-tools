function vals = getDim(cellData, nodeIDs, whichDim)
  % get the XYZ location in viking for specific nodeIDs
  % INPUT:
  %   cellData      structure from parseCellData.m
  %   nodeIDs       node id numbers
  %   whichDim      string with 1 or more of 'XYZ'
  % OUTPUT:
  %   vals          numDims x numNode matrix
  %
  % 6May2017 - SSP - created

  whichDim = upper(whichDim);
  numNodes = length(nodeIDs);
  numDims = length(whichDim);

  vals = zeros(numDims, numNodes);

  for ii = 1:numDims
    ind = strfind('XYZ', whichDim(ii));
    for jj = 1:numNodes
      vals(ii,jj) = cellData.nodes(jj).locationXYZ(1, ind);
    end
  end
