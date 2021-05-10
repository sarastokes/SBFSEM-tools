function [X1, Y1, ipl] = stratificationMap(section, source, varargin)
% STRATIFICATIONMAP
%
% History:
%   11Nov2019 - SSP
% -------------------------------------------------------------------------

    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'contourPoints', [], @isvector);
    addParameter(ip, 'useViking', false, @islogical);
    addParameter(ip, 'faceAlpha', 1, @isnumeric);
    addParameter(ip, 'INL', [], @(x) isa(x, 'sbfsem.builtin.INLBoundary'));
    addParameter(ip, 'GCL', [], @(x) isa(x, 'sbfsem.builtin.GCLBoundary'));
    parse(ip, varargin{:});
    
    ax = ip.Results.ax;
    contourPoints = ip.Results.contourPoints;
    useViking = ip.Results.useViking;
    faceAlpha = ip.Results.faceAlpha;
    GCL = ip.Results.GCL;
    INL = ip.Results.INL;
    
    % Load boundary markers, if necessary
    if isempty(INL)
        INL = sbfsem.builtin.INLBoundary(source, true);
    end
    if isempty(GCL)
        GCL = sbfsem.builtin.GCLBoundary(source, true);
    end
    
    % Get volume scale in microns
    volumeScale = getODataScale(source);
    volumeScale = volumeScale ./ 1e3;
    
    [X1, Y1] = meshgrid(INL.newXPts, INL.newYPts);
    vINL = interp2(X1, Y1, INL.interpolatedSurface,...
        X1(:), Y1(:));
    
    [X2, Y2] = meshgrid(GCL.newXPts, GCL.newYPts);
    vGCL = interp2(X2, Y2, GCL.interpolatedSurface,...
        X1(:), Y1(:));
    
    [m, n] = size(X1);
    
    Z = (section*volumeScale(3)) + zeros(size(vINL));
    ipl = (Z - vINL) ./ ((vGCL - vINL) + eps);
    ipl = reshape(ipl, [m, n]);
    
    if useViking    
        X1 = reshape(bsxfun(@rdivide, X1(:), volumeScale(1)), [m, n]);
        Y1 = reshape(bsxfun(@rdivide, Y1(:), volumeScale(2)), [m, n]);
    end
    
    if isempty(ax)
        ax = axes('Parent', figure()); 
    end
    
    hold(ax, 'on');
    surf(ax, X1, Y1, ipl, 'FaceAlpha', faceAlpha);
    shading(ax, 'interp'); 
    axis(ax, 'equal', 'tight');
    colormap(ax, pmkmp(10, 'cubicl'));
    set(ax, 'CLim', [0 1]);
    addColorbarIPL(ax);
    title(ax, sprintf('Stratification at Section %u', section));
    
    view(ax, 0, -90); set(ax, 'YDir', 'reverse');
    contour(ax, X1, Y1, ipl, [1 1], 'k', 'LineWidth', 1);
    contour(ax, X1, Y1, ipl, [0 0], 'k', 'LineWidth', 1);
    
    if ~isempty(contourPoints)
        for i = 1:numel(contourPoints)
            contour(ax, X1, Y1, ipl, [contourPoints(i), contourPoints(i)],...
                'k', 'LineStyle', '--', 'LineWidth', 0.8);
        end
    end
    
    