function nodeIDs = nearestNodes(neuron, synapseName, swc)
    % NEARESTNODES
    %
    % Syntax:
    %   nodeIDs = nearestNodes(neuron, synapseName, swc)
    %
    % Inputs:
    %   neuron          Neuron object
    %   synapseName     Target synapse name
    % Optional inputs:
    %   swc             sbfsem.io.SWC object (otherwise computed)
    %
    % History:
    %   3Jul2018 - SSP
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'NeuronAPI'), 'Input a neuron object');

    xyz = neuron.getSynapseXYZ(synapseName);

    if isempty(xyz)
        nodeIDs = [];
        return
    end

    if nargin < 3 || ~isa(swc, 'sbfsem.io.SWC')
        swc = sbfsem.io.SWC(neuron);
    end

    nodeIDs = zeros(size(xyz,1), 1);

    for i = 1:size(xyz, 1)
        [~, nodeIDs(i)] = min(fastEuclid3d(xyz(i, :), swc.T.XYZ));
    end
