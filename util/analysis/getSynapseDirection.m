function d = getSynapseDirection(somaXYZ, synapseXYZ)
    % GETSYNAPSEDIRECTION
    %
    % Syntax:
    %   d = getSyntaxDirection(somaXYZ, synapseXYZ);
    %
    % Input:
    %   somaXYZ         X, Y coordinates of soma location
    %   synapseXYZ      X, Y coordinates of synapses
    %
    % Output:
    %   d       Angle of synapse(s) from soma (degrees, 0-360, 0 = north)
    %
    % Note:
    %   Z coordinate is ignored, if included
    %
    % History:
    %   15Nov2019 - SSP
    % --------------------------------------------------------------------
   
    % v1 = [somaXYZ(1:2), 0];
    % if size(synapseXYZ, 1) ~= 1 && size(somaXYZ, 1) == 1
    %     v1 = repmat(v1, [size(synapseXYZ, 1), 1]);
    % end
    
    % v2 = synapseXYZ;
    % if size(v2, 2) == 3
    %     v2(:, 3) = 0;
    % end
    % nvec = [0 0 1];
    
    % d = zeros(size(synapseXYZ, 1), 1);
    % for i = 1:numel(d)
    %     x = cross(v1(i, :), v2(i, :));
    %     c = sign(dot(x, nvec)) * norm(x);
    %     d(i) = atan2d(c, dot(v1(i,:), v2(i,:)));
    % end
    
    x = synapseXYZ(:, 1) - somaXYZ(:, 1);
    y = synapseXYZ(:, 2) - somaXYZ(:, 2);

    d = wrapTo360(rad2deg(atan2(x, y)));