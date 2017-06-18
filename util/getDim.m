function vals = getDim(nodeData, nodeNames, whichDim)
  % get the XYZ location in viking for specific nodeIDs
  % INPUT:
  %   nodeData      structure from parseNodesEdges.m
  %   nodeNames     cell of nodeNames
  %   whichDim      string with 1 or more of 'XYZ'
  % OUTPUT:
  %   vals          numDims x numNode matrix
  %
  % 6May2017 - SSP - created
  % 16Jun2017 - SSP - updated for new map structure

  % check for call from obj or struct
  if isfield(nodeData, 'props')
      nodeData = cellData.props;
  end
  
  whichDim = upper(whichDim);
  numNodes = length(nodeNames);
  numDims = length(whichDim);

  vals = zeros(numDims, numNodes);

  for ii = 1:numNodes
      try
        xyz = nodeData.xyzMap(char(nodeNames{ii}));
      catch
          fprintf('no output for %s!\n', char(nodeNames{ii}));
      end
    for jj = 1:numDims
      ind = strfind('XYZ', whichDim(jj));
      vals(jj, ii) = xyz(ind);
    end
  end