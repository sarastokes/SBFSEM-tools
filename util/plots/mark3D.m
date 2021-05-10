function h = mark3D(xyz, varargin)
    % MARK3D
    %
    % Description:
    %   Wrapper for Matlab plot3/scatter3 function with SBFSEM-tools keys, 
    %   defaults and auto splitting of XYZ for fast command line use
    %
    % Syntax:
    %   h = mark3D(xyz, varargin);
    %
    % Inputs:
    %   xyz         X, Y and Z data for plot3 (N x 3)
    % Optional key/value inputs:
    %   ax          Parent axes handle ('Parent' works too)
    %   Color       plot3's MarkerFaceColor (default = red)
    %   EdgeColor   plot3's MarkerEdgeColor (default = black)
    %   Marker      plot3's Marker (default = 'o')
    %   Scatter     Use scatter3 function instead of plot3
    %
    % Outputs:
    %   h           Handle to created line object
    %
    % Note:
    %   Specify useScatter if markers need to be transparent.
    %
    % See also:
    %   PLOT3, SYNAPSEMARKER, SYNAPSESPHERE
    %
    % History:
    %   15Nov2019 - SSP
    %   16Jun2020 - SSP - Added option to use scatter3
    %   06Apr2021 - SSP - Added empty return value when xyz is empty
    % ---------------------------------------------------------------------
    
    if isempty(xyz)
        h = [];
        return
    end

    ip = inputParser();
    ip.KeepUnmatched = true;
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'Parent', [], @ishandle);
    addParameter(ip, 'Marker', 'o', @ischar);
    addParameter(ip, 'EdgeColor', [0, 0, 0], @(x) ischar(x) || isvector(x));
    addParameter(ip, 'Color', [1, 0.25, 0.25], @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceAlpha', 1, @isnumeric);
    addParameter(ip, 'EdgeAlpha', 1, @isnumeric);
    addParameter(ip, 'Scatter', false, @islogical);
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

    if ip.Results.Scatter
        % Is this a glitch with scatter3 and empty ip.Unmatched?
        if isempty(fieldnames(ip.Unmatched))
            h = scatter3(ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                'MarkerFaceColor', ip.Results.Color,...
                'MarkerEdgeColor', ip.Results.EdgeColor,...
                'MarkerFaceAlpha', ip.Results.FaceAlpha,...
                'MarkerEdgeAlpha', ip.Results.EdgeAlpha);
        else
            h = scatter3(ax, xyz(:, 1), xyz(:, 2), xyz(:, 3),...
                'MarkerFaceColor', ip.Results.Color,...
                'MarkerEdgeColor', ip.Results.EdgeColor,...
                'MarkerFaceAlpha', ip.Results.FaceAlpha,...
                'MarkerEdgeAlpha', ip.Results.EdgeAlpha,...
                ip.Unmatched);
        end
    else
        h = plot3(xyz(:, 1), xyz(:, 2), xyz(:, 3), ...
            'Parent', ax, ...
            'Marker', ip.Results.Marker, ...
            'MarkerFaceColor', ip.Results.Color, ...
            'MarkerEdgeColor', ip.Results.EdgeColor, ...
            'LineStyle', 'none', ip.Unmatched);
    end
    drawnow;
