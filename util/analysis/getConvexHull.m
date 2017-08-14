function result = getConvexHull(xyz, plotFlag)
  % Get the convex hull and plot result
  % INPUTS:
  %   neuron or matrix of points
  % OPTIONAL:
  %   plotFlag      [false] plot results
  %
  % 12Aug2017 - SSP - created

  if isa(xyz, 'Neuron')
    str = ['c' num2str(xyz.cellData.cellNum)];
    xyz = xyz.dataTable.XYZum;
  else % matrix
    if size(xyz, 2) ~= 3
      xyz = xyz';
    end
    str = [];
  end

  if nargin < 2
    plotFlag = false;
  end

  % get the dimensions
  [x, y, z] = size(xyz);
  % get the z-axis direction that captures the most variance
  [u, ~, ~] = svd(reshape(xyz, x * y, z));
  % get the first PC
  normalvec = reshape(u(:, 1), x, y);
  % project to the best vector
  uv = xyz * null(normalvec);
  % get convex hull in that plane
  k = convexhull(uv(:,1), uv(:,2));
  % get the area of polygon from convex hull
  A = polyarea(uv(hull, 1), uv(hull,2));

  if nargout == 1
    result.xy = uv;
    result.k = k;
    result.A = A;
  end

  if plotFlag
    figure('Name',[str, 'dendritic field']);
    hold on;
    plot(uv(:, 1), uv(:, 2), '.k');
    plot(uv(k, 1), y(k, 2), '-b');
    title(sprintf('dendritic field (A=%u um^2)', A));
  end
