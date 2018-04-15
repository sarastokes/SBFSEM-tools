function [a, b] = getAB(normal)
    % GETAB
    % Originally from plot3t

    % A normal vector only defines two rotations not the in plane rotation.
    % Thus a (random) vector is needed which is not orthogonal with the
    % normal vector.

    randomv = [0.57745, 0.5774, 0.57735];

    % Calculate 2D to 3D transform parameters
    a = normal - randomv/(randomv*normal'); 

    a = a/sqrt(a*a');

    b = cross(normal, a); 
    b = b / sqrt(b * b');