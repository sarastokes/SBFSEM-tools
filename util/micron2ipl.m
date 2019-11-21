function ipl = micron2ipl(xyz, source)
    % MICRON2IPL
    %
    % Syntax:
    %   ipl = micron2ipl(xyz, source)
    % 
    % Inputs:
    %   xyz             Locations (N x 3)
    %   source          Volume name or abbreviation
    %
    % Output:
    %   ipl             ipl depth of each location (in %)
    %
    % See also:
    %   iplDepth, getSynapseStratification
    %
    % History:
    %   11Nov2019 - SSP
    % ---------------------------------------------------------------------

    % Load cached boundary markers
    GCL = sbfsem.builtin.GCLBoundary(source, true);
    INL = sbfsem.builtin.INLBoundary(source, true);

    [X, Y] = meshgrid(GCL.newXPts, GCL.newYPts);
    vGCL = interp2(X, Y, GCL.interpolatedSurface,...
        xyz(:, 1), xyz(:, 2));
    
    [X, Y] = meshgrid(INL.newYPts, INL.newYPts);
    vINL = interp2(X, Y, INL.interpolatedSurface,...
        xyz(:, 1), xyz(:, 2));
    
    ipl = (xyz(:, 3) - vINL) ./ ((vGCL - vINL) + eps);
    % ipl(isnan(ipl)) = [];