function hideAxes(gObj)
    % HIDEAXES
    % 
    % Description:
    %   Toggle axes visibility without removing completely
    % 
    % Syntax:
    %   hideAxes(gObj);
    %
    % Inputs:
    %   gObj      Figure or axes handle
    %
    % History:
    %   6Jan2018 - SSP
    %   24Jan2018 - SSP - added option to show axes again
    %   25Apr2018 - SSP - applies to all axes in a figure
    % ---------------------------------------------------------------------
    if nargin < 1
        gObj = gcf;
    else
        assert(ishandle(gObj), 'Input an axes or figure handle');
    end
    
    switch class(gObj)
        case 'matlab.graphics.axis.Axes'
            ax = gObj;
        case 'matlab.ui.Figure'
            ax = findall(gObj, 'Type', 'axes');
        otherwise
            warning('hideAxes:InvalidInput',...
                'Input must be handle to a figure or axes');
            return
    end
    
    for i = 1:numel(ax)
        bkgd = ax(i).Color;
        frgd = invertColor(bkgd);
        
        if ax(i).XColor == bkgd
            set(ax(i), 'XColor', frgd, 'YColor', frgd', 'ZColor', frgd); 
        else
            set(ax(i), 'XColor', bkgd, 'YColor', bkgd, 'ZColor', bkgd);
        end
    end
end

function newColor = invertColor(oldColor)
    if oldColor == [0, 0, 0]
        newColor = 'w';
    elseif oldColor == [1, 1, 1]
        newColor = 'k';
    else % Do nothing if not black/white
        newColor = oldColor;
    end
end