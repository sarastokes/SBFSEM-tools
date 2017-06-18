function fh = synplotXY(cellData, syns, axHandle)
  % create a scatter plot of synapse types against XY coordinates
  %
  % INPUT:
  %   cellData      structure from parseCellData.m
  %   syns          synapse types (1 = string, 2 = cellstr, 3 = 'all')
  % OPTIONAL:
  %   axHandle      existing axis handle
  %
  % OUTPUT:
  %   fh            figure handle (optional)
  %
  % 6May2017 - SSP - created
  % 16Jun2017 - SSP - ready and updated to localName setup

  if nargin < 3
    fh = figure('Color', 'w');
    axHandle = axes('Parent', fh);
  else
    gca = axHandle;
    fh = gcf;
  end

  sc = getStructureColors();

  nodeDir = getSynNodes(cellData, syns);

  if ischar(syns)
    vals = getDim(cellData, nodeDir, 'XY');

    plot(vals(1,:), vals(2,:), 'Marker', 'o',...
      'Color', sc(syns), 'LineStyle', 'none',... 
      'DisplayName', syns); hold on;
  else
    for ii = 1:length(syns)
      vals = getDim(cellData, nodeDir{ii}, 'XY');

      plot(axHandle, vals(1,:), vals(2,:), 'o',...
        'Color', sc(syns{ii}), 'LineStyle', 'none',... 
        'DisplayName', syns{ii}); hold on;
    end
  end
  
  legend('-DynamicLegend');

  set(legend, 'FontSize', 10, 'EdgeColor', 'w');
  xlabel('x coordinates');
  ylabel('y coordinates');
  tightfig(gcf);
