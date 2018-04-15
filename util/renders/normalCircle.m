function [X, a, b] = normalCircle(angles, angleOffset, a, b)
    % This function rotates a 2D circle in 3D to be orthogonal with
    % a normal vector.
    %
    % Inputs:
    %   angles      The location of vertices around the circle (degrees)
    %   angleOffset The (in plane) rotation to apply to the vertices
    %   a, b        Normal vectors
    %
    % Notes:
    % The angle offset is especially important for the Cylinder render code
    % as it ensures the points are lined up with the points on a previous
    % circle. This does not change the circle itself, but will greatly
    % improve the process of connecting vertices into faces.
    %
    % History:
    %   Originally a helper function in plot3t
    %   15Apr2018 - SSP - moved from sbfsem.render.Cylinder, 
    %                     commented and modified slightly
    % ---------------------------------------------------------------------
    
    % 2D circle coordinates

    circ=[cosd(angles + angleOffset); sind(angles + angleOffset)]';
    
    % Rotation
    X = [circ(:,1).*a(1) circ(:,1).*a(2) circ(:,1).*a(3)]+...
        [circ(:,2).*b(1) circ(:,2).*b(2) circ(:,2).*b(3)];