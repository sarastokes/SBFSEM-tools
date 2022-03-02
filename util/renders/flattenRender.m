function flattenRender(h, source)
    % FLATTENRENDER
    % 
    % Syntax:
    %   flattenRender(h, source)
    %
    % Inputs:
    %   h           handle
    %       Handle to "patch" or an axis containing "patch" objects
    %   source      char
    %       Volume name or abbreviation
    %
    % History:
    %   12Dec2020 - SSP
    %   02Mar2022 - SSP - Added better documentation
    % ---------------------------------------------------------------------

    validatestring(class(h),... 
        {'matlab.graphics.axis.Axes', 'matlab.graphics.primitive.Patch'},... 
        mfilename);

    % Get the IPL boundaries
    GCL = sbfsem.builtin.GCLBoundary(source, true);
    INL = sbfsem.builtin.INLBoundary(source, true);
    
    if isa(h, 'matlab.graphics.axis.Axes')
        ax = h;
        h = findall(gca, 'Type', 'patch');
    elseif isa(h, 'patch')
        ax = h.Parent;
    end

    for i = 1:numel(h)
        doFlattening(GCL, INL, h(i));
    end
    axis(ax, 'equal', 'tight');
end

function doFlattening(GCL, INL, h)
    xyz = h.Vertices;

    [X, Y] = meshgrid(GCL.newXPts, GCL.newYPts);
    vGCL = interp2(X, Y, GCL.interpolatedSurface, ...
        xyz(:, 1), xyz(:, 2));
    [X, Y] = meshgrid(INL.newXPts, INL.newYPts);
    vINL = interp2(X, Y, INL.interpolatedSurface, ...
        xyz(:, 1), xyz(:, 2));

    halfway = (0.5 * (vGCL - vINL)) + vINL;
    zOffsets = 80 - halfway;

    h.Vertices(:, 3) = h.Vertices(:, 3) + zOffsets;
end