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

    x = synapseXYZ(:, 1) - somaXYZ(1);
    y = synapseXYZ(:, 2) - somaXYZ(2);

    d = wrapTo360(rad2deg(atan2(x, y)));