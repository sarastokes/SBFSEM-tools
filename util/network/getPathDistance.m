function [D, distances] = getPathDistance(neuron, A, B, varargin)
    % GETPATHDISTANCE
    % 
    % Syntax:
    % [D, distances] = getPathDistance(neuron, A, B, varargin)
    % 
    % History:
    %   31Dec2020 - SSP
    % ---------------------------------------------------------------------

    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'Dim', 3, @(x) ismember(x, [2 3]));
    parse(ip, varargin{:});

    dim = ip.Results.Dim;

    nodes = neuron.getBranchNodes(A, B);
    A = nodes.XYZum(1:end - 1, :);
    B = nodes.XYZum(2:end, :);

    if dim == 2
        distances = bsxfun(@fastEuclid2d, A, B);
    else
        distances = bsxfun(@fastEuclid3d, A, B);
    end
    D = sum(distances);

