function [ID, minDistance] = getNearestAnnotation(neuron, xyz, verbose)
    % GETNEARESTANNOTATION
    %
    % Syntax:
    %   [ID, minDistance] = getNearestAnnotation(neuron, xyz, verbose)
    %
    % History:
    %   31Dec2020 - SSP
    % ---------------------------------------------------------------------

    if nargin < 3
        verbose = false;
    end
    T = neuron.getCellNodes();

    distances = fastEuclid3d(xyz, T.XYZum);
    [minDistance, idx] = min(distances);

    ID = T{idx, 'ID'};
    if verbose
        fprintf('\tNearest annotation %u is %.3g away microns\n', ID, minDistance);
    end