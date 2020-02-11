function hideAxes(gObj)
    % TOGGLEAXES
    % 
    % Description:
    %   Hide axes visibility without removing completely
    % 
    % Syntax:
    %   hideAxes(gObj);
    %
    % Inputs:
    %   gObj      Figure or axes handle
    %
    % See also:
    %   TOGGLEAXES
    %
    % History:
    %   6Jan2018 - SSP
    %   24Jan2018 - SSP - added option to show axes again
    %   25Apr2018 - SSP - applies to all axes in a figure
    %   4Feb2020 - SSP - removed toggle options
    % ---------------------------------------------------------------------

    if nargin < 1
        gObj = gcf;
    else
        assert(ishandle(gObj), 'Input axes or figure handle');
    end

    switch class(gObj)
        case 'matlab.graphics.axis.Axes'
            ax = gObj;
        case 'matlab.ui.Figure'
            ax = findall(gObj, 'Type', 'axes');
        otherwise
            warning('toggleAxes:InvalidInput',...
                'Input must be handle to a figure or axes')
    end

    for i = 1:numel(ax)
        bkgd = ax(i).Color;
        set(ax(i), 'XColor', bkgd, 'YColor', bkgd, 'ZColor', bkgd);
    end

