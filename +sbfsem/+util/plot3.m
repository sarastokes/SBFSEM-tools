function h = plot3(xyz, varargin)
    % PLOT3
    %
    % Description:
    %   Wrapper for Matlab plot3 function with SBFSEM-tools keys, defaults 
    %   and auto splitting of XYZ inputs for fast command line use
    %
    % Inputs:
    %   xyz         X, Y and Z data for plot3 (N x 3)
    % Optional key/value inputs:
    %   ax          Parent axes handle ('Parent' works too)
    %   Color       plot3's MarkerFaceColor (default = red)
    %   EdgeColor   plot3's MarkerEdgeColor (default = black)
    %   Marker      plot3's Marker (default = 'o')
    %
    % Outputs:
    %   h           Handle to created line object
    %
    % See also:
    %   PLOT3, SYNAPSEMARKER, SYNAPSESPHERE
    %
    % History:
    %   15Nov2019 - SSP
    % ---------------------------------------------------------------------

    ip = inputParser();
    ip.KeepUnmatched = true;
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'Parent', [], @ishandle);
    addParameter(ip, 'Marker', 'o', @ischar);
    addParameter(ip, 'EdgeColor', 'k', @(x) ischar(x) || isvector(x));
    addParameter(ip, 'Color', [1, 0.25, 0.25], @(x) ischar(x) || isvector(x));
    parse(ip, varargin{:});

    if ~isempty(ip.Results.ax)
        ax = ip.Results.ax;
    elseif ~isempty(ip.Results.Parent)
        ax = ip.Results.Parent;
    else  % Create new figure
        ax = axes('Parent', figure());
        hold(ax, 'on');
        axis(ax, 'equal');
        grid(ax, 'on');
    end

    h = plot3(xyz(:, 1), xyz(:, 2), xyz(:, 3), ...
        'Parent', ax, ...
        'Marker', ip.Results.Marker, ...
        'MarkerFaceColor', ip.Results.Color, ...
        'MarkerEdgeColor', ip.Results.EdgeColor, ...
        'LineStyle', 'none', ip.Unmatched);
