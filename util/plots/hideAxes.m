function hideAxes(ax)
    % HIDEAXES
    % 
    % Description:
    %   Toggle axes visibility without removing completely
    %
    % Inputs:
    %   ax      Axis handle
    %
    % 6Jan2017 - SSP
    % ---------------------------------------------------------------------
    
    assert(ishandle(ax), 'Input an axes handle');
    set(ax, 'XColor', ax.Color, 'YColor', ax.Color, 'ZColor', ax.Color);