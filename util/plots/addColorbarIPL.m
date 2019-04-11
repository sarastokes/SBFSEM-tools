function h = addColorbarIPL(axHandle)
    % ADDCOLORBARIPL
    %
    % Description:
    %   Add IPL depth colormap colorbar
    %
    % Syntax:
    %   h = addColorbarIPL(axHandle)
    %
    % Inputs:
    %   axHandle        Axes handle (default = gca)
    % Outputs:
    %   h               Colorbar handle
    %
    % History:
    %   3Apr2019 - SSP - Moved from RenderApp/onToggleColorbar
    % ---------------------------------------------------------------------

    if nargin < 1
        axHandle = gca;
    end

    h = colorbar(axHandle,...
        'Direction', 'reverse',...
        'TickDirection', 'out',...
        'AxisLocation', 'out',...
        'Location', 'eastoutside');
    h.Label.String = 'IPL Depth (%)';
    if strcmpi(axHandle.CLimMode, 'manual')
        h.Ticks = 0:0.25:1;
    end
    h.TickLabels = 100 * h.Ticks;

    if axHandle.Color == [0 0 0]
        h.Color = 'w';
    end