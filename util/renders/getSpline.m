function [x, y] = getSpline(x0, y0)
    % GETSPLINE
    %
    % Description:
    %   Wraps catmull-rom spline function, adds padding to x,y vectors
    %
    % See also:
    %   CATMULLROMSPLINE, RENDERCLOSEDCURVE, SBFSEM.BUILTIN.CLOSEDCURVE
    % 
    % History:
    %   9Apr2018 - SSP
    % ---------------------------------------------------------------------
    
    x0 = x0(:);
    y0 = y0(:);
    x0 = cat(1, x0, x0(1:3));
    y0 = cat(1, y0, y0(1:3));
    [x, y] = catmullRomSpline(x0, y0);