function [D, IDs] = getSynapseSomaPathLength(neuron, synapseType)
    % GETSYNAPSESOMAPATHLENGTH
    %
    % Description:
    %   Get distance from soma measured as path length
    %
    % Syntax:
    %   [D, IDs] = getSynapseSomaPathLength(neuron, synapseType)
    %
    % Inputs:
    %   neuron              Neuron object
    %   synapseType     Synapse name
    %
    % Output:
    %   D                    distance of each synapse from soma in microns
    %   IDs                 synapse IDs corresponding to each distance in D
    %
    % See also:
    %   getSynapseSomaDistance, getNearestAnnotation, getPathDistance
    %
    % History:
    %   01Jan2020 - SSP
    % ---------------------------------------------------------------------

    neuron.checkSynapses();

    xyz = neuron.getSynapseXYZ(synapseType);
    
    if isempty(xyz)
        error('No synapses of type %s found!\n', synapseType);
    end

    D = zeros(size(xyz, 1), 1);
    for i = 1:size(xyz, 1)
        ID = getNearestAnnotation(neuron, xyz(i, :));
        D(i) = getPathDistance(neuron, neuron.getSomaID(), ID);
    end

    if nargout == 2
        IDs = neuron.getSynapseIDs(synapseType);
    end
