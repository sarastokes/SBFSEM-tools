function synplotZ(cellData, syns, varargin)
  % bar graph number of synapses along a single dimension
  %
  % INPUTS:
  % Required:
  %   cellData      from parseCellData.m
  %   syns          synapse types (for >1 use cellstr, for all use 'all')
  % Optional:
  %   dim           x,y or z (default = z)
  %   ax            existing axis (default makes a new figure)
  %   numBins       how many bins to use for histogram (default = 10)
  %
  % 6May2017 - SSP - created

  ip = inputParser();
  ip.addParameter('dim', 'Z', @ischar);
  ip.addParameter('numBins', 10, @isnumeric);
  ip.addParameter('ax', [], @ishandle);
  ip.parse(varargin{:});
  whichDim = ip.Results.dim;
  numBins = ip.Results.numBins;
  axHandle = ip.Results.ax;

  if isempty(axHandle)
    fh = figure('Color', 'w');
    axHandle = axes('Parent', fh);
  else
    gca = axHandle;
    fh = gcf;
  end

  sc = getStructureColors();

  nodeIDs = getSyn(cellData, syns);

  if ischar(syns)
    if strcmp(lower(syns), 'all')
      syns = cellData.typeData.names;
      numSyn = length(syns);
    else
      numSyn = 1;
    end
  else
    numSyn = length(syns);
  end

  vals = cell(1, length(syns));
  for ii = 1:numSyn
    vals{ii} = getDim(cellData, nodeIDs{ii}, whichDim);
  end

  minVal = min(cellfun(@min, vals));
  maxVal = max(cellfun(@max, vals));
  binSize = (maxVal-minVal+1)/numBins;
  if binSize > 1
    binCenters = 0:numBins-1;
    binCenters = minVal + (binSize*binCenters)/2;
  elseif binSize < 1
    warndlg(sprintf('bin size is less than 1, changing from %u bins to %u bins\n', numBins, minVal:maxVal));
    binSize = 1;
    binCenters = minVal:maxVal;
    numBins = length(binCenters);
  else % binSize = 1
    binCenters = minVal:maxVal;
  end

  counts = zeros(numBins, numSyn);

  for ii = 1:numSyn
    tmp = vals{ii};
    for jj = 1:numBins
      ind = find(tmp >= (minVal + binSize*(jj-1)) & tmp < (minVal + binSize*jj));
      counts(jj,ii) = length(ind);
    end
  end
  size(counts)
  size(binCenters)

  bar(binCenters, counts, 'stacked');
  legend(syns);
  set(legend, 'FontSize', 10, 'EdgeColor', 'w');
