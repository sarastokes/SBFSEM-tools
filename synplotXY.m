function fh = synplotXY(cellData, syns, axHandle)
  % create a scatter plot of synapse types against XY coordinates
  % INPUT:
  %   cellData      structure from parseCellData.m
  %   synTypes      synapse types (1 = string, 2 = cellstr, 3 = 'all')
  %
  % OUTPUT:
  %   fh            figureHandle
  %
  % 6May2017 - SSP - created

  if nargin < 3
    fh = figure('Color', 'w');
    axHandle = axes('Parent', fh);
  else
    gca = axHandle;
    fh = gcf;
  end

  hold all;
  sc = getStructureColors();

  nodeDir = getSyn(cellData, syns);
  % if ischar(syns)
  %   numSyn = 1;
  % else
  %   numSyn = length(syns);
  % end

    vals = getDim(cellData, nodeDir, 'XY');
    if size(vals,1) ~= 2
      error('wrong values size returned');
    end

    if ischar(syns)
      vals = getDim(cellData, nodeDir, 'XY');
      plot(vals(1,:), vals(2,:), 'o',...
        'Color', sc(syns), 'DisplayName', syns);
      legend('-DynamicLegend');
    else
      for ii = 1:length(syns)
        vals = getDim(cellData, nodeDir{ii}, 'XY');
        plot(axHandle, vals(1,:), vals(2,:), 'o',...
        'Color', sc(syns{ii}), 'DisplayName', syns{ii});
      end
      legend('-DynamicLegend');
    end

  set(legend, 'FontSize', 10, 'EdgeColor', 'w');
  xlabel('x coordinates');
  ylabel('y coordinates');
