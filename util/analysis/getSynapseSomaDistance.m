function d = getSynapseSomaDistance(neuron, synapseName)
    % GETSYNAPSESOMADISTANCE
    % 
    % Description:
    %   Calculates radial distance from soma for synapses of a given type
    %
    % Syntax:
    %   d = getSynapseSomaDistance(neuron, synapseName)
    %
    % See also:
    %   SOMADISTANCEVIEW
    %
    % History:
    %   5Dec2019 - SSP - Copied calculation from SomaDistanceView
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input Neuron object');
    neuron.checkSynapses();

    if ischar(synapseName)
        synapseName = sbfsem.core.StructureTypes(synapseName);
        xyz = neuron.getSynapseXYZ(synapseName);
    end

    if ~isempty(xyz)
        d = fastEuclid3d(neuron.getSomaXYZ, xyz);
    else
        d = [];
    end
