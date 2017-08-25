function addTrace(mat, varargin)
    % ADDTRACE  Fast plot function for cone tracings
    %
    % 21Aug2017 - SSP - created

ip = inputParser();
ip.addParameter('ax', [], @ishandle);
ip.addParameter('co', [0 0 0], @isvector);
ip.parse(varargin{:});
co = ip.Results.co;
if isempty(ip.Results.ax)
    fh = figure();
    ax = axes('parent', fh);
else
    ax = ip.Results.ax;
end

plot(mat(1,:), mat(2,:), '.',... 
    'MarkerSize', 3, 'Color', co,...
    'Parent', ax);
set(gca, 'XColor', 'w', 'YColor', 'w');
axis equal;