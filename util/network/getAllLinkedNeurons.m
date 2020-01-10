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
    %   9Jan2020 - SSP - Added label query and reordered output
    % ---------------------------------------------------------------------
    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input neuron object');
    
    synList = neuron.synapseNames();
    
    synTable = [];
    
    for i = 1:numel(synList)
        fprintf('\tImporting %s links...\n', char(synList(i)));
        T = getLinkedNeurons(neuron, synList(i));
        T.SynapseType = repmat(string(synList(i)), [height(T), 1]);
        synTable = [synTable; T];  %#ok
    end
    
    x = sbfsem.io.OData(neuron.source);
    synTable.Label = repmat("", [height(synTable), 1]);
    ind = find(~isnan(synTable.NeuronID));
    
    for i = 1:numel(ind)
        lbl = x.getLabel(synTable.NeuronID(ind(i)));
        if ~isempty(lbl)
            synTable{ind(i), 'Label'} = string(lbl); %#ok
        end
    end
    
    synTable.Properties.VariableNames = {'NeuronID', 'SynapseID', 'SynapseXYZ', 'SynapseType', 'NeuronLabel'};
    synTable = synTable(:, [1:2, 4:5, 3]);
    synTable = sortrows(synTable, 'NeuronID');
end
