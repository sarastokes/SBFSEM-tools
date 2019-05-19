function synTable = getAllLinkedNeurons(neuron)
    % GETALLLINKEDNEURONS
    %
    % Description:
    %   Get linked neurons for all synapse types
    %
    % Syntax:
    %   synapseTable = getAllLinkedNeurons(neuron)
    %
    % Input:
    %   neuron      Neuron object
    %
    % See Also:
    %   GETLINKEDNEURONS, NEURON
    %
    % History:
    %   18Nov2018 - SSP
    % ---------------------------------------------------------------------
    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input neuron object');
    
    synList = neuron.synapseNames();
    
    synTable = [];
    
    for i = 1:numel(synList)
        fprintf('Importing %s links...\n', char(synList(i)));
        T = getLinkedNeurons(neuron, synList(i));
        T.SynapseType = repmat(string(synList(i)), [height(T), 1]);
        synTable = [synTable; T];  %#ok
    end
    
    synTable.Properties.VariableNames = {'NeuronID', 'SynapseID', 'SynapseXYZ', 'SynapseType'};
    synTable = sortrows(synTable, 'NeuronID');
end
