function hideAxes(ax)
    % HIDEAXES
    % 
    % Description:
    %   Toggle axes visibility without removing completely
    %
    % Inputs:
    %   ax      Axis handle
    %
    % History:
    %   6Jan2018 - SSP
    %   24Jan2018 - SSP - added option to show axes again
    % ---------------------------------------------------------------------
    if nargin < 1
        ax = gca;
    else
        assert(ishandle(ax), 'Input an axes handle');
    end
    
    if ax.Color == ax.XColor
        set(ax, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
    else
        set(ax, 'XColor', ax.Color, 'YColor', ax.Color, 'ZColor', ax.Color);
    end