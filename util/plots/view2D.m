function view2D(gObj)
    % VIEW2D
    %
    % Description:
    %   Setup figure/axis for 2D render views
    %
    % Syntax:
    %   view2D(gObj)
    %
    % Inputs:
    %   axHandle        handle to axis or figure
    % 
    % History:
    %   4Feb2020 - SSP
    % ---------------------------------------------------------------------  
    
    if nargin == 0
        gObj = gca;
    end

    if isa(gObj, 'matlab.graphics.axis.Axes')
        view(gObj, 0, 90);
    end

    set(findall(gObj, 'Type', 'patch'), 'FaceAlpha', 1);

    delete(findall(gObj, 'Type', 'light'));