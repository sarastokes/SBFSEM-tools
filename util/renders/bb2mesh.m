function [X,Y] = bb2mesh(boundingBox)
    %BB2MESH  Create 2D Cartesian grid from bounding box
    % Input:
    %   boundingBox     [xmin, xmax, ymin, ymax]
    % Output:
    %   X               x-axis grid
    %   Y               y-axis grid
    %
    %   8Dec2017 - SSP
    %
    %   See also XYZR2BB, GROUPBOUNDINGBOX, MESHGRID
    
    [X, Y] = meshgrid(  boundingBox(1):boundingBox(2),...
                        boundingBox(3):boundingBox(4));
    
    