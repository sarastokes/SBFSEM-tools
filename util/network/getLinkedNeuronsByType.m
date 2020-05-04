function [typeTable, T] = getLinkedNeuronsByType(neuron, synapseName)
% GETLINKEDNEURONSBYTYPE
%
% Syntax:
%   [typeTable, neuronTable] = getLinkedNeuronsByType(neuron, synapseName);
%
% Inputs:
%   neuron          Neuron object
%   synapseName     char, synapse to analyze (e.g. 'RibbonPost')
%
% Outputs:
%   typeTable       Linked neurons grouped by type (aka label)
%   neuronTable     Synapses grouped by linked neuron
%   
% Notes:
%   Type is read from the 'label' assigned to each structure.
%
% History:
%   22Apr2020 - SSP 
% ------------------------------------------------------------------------
    neuron.checkLinks();

    T0 = neuron.links(strcmpi(neuron.links.SynapseType, synapseName), :);
    if isempty(T0)
        error('SBFSEM/GETLINKEDNEURONSBYTYPE: No match for %s', synapseName);
    end

    % Group the synapses by linked neuron
    [G, groupNames] = findgroups(T0.NeuronID);
    N = splitapply(@numel, T0.NeuronID, G);

    labels = {};
    for i = 1:numel(groupNames)
        labels = cat(1, labels, T0{find(T0.NeuronID == groupNames(i), 1), 'NeuronLabel'});
    end

    labels(cellfun(@isempty, labels)) = 'N/A';

    T = table(groupNames, labels, N,... 
        'VariableNames', {'NeuronID', 'NeuronLabel', 'NumSynapses'});
    T = sortrows(T, 'NumSynapses', 'descend');

    % Group the neurons by type (label)
    [L, labelNames] = findgroups(T.NeuronLabel);
    numSynapsesByType = splitapply(@sum, T.NumSynapses, L);
    numNeuronsByType = splitapply(@numel, T.NumSynapses, L);

    typeTable = table(labelNames, numSynapsesByType, numNeuronsByType,...
        'VariableNames', {'Label', 'NumSynapses', 'NumNeurons'});
    typeTable = sortrows(typeTable, 'NumSynapses', 'descend');
    
    pieLabels = {};
    for i = 1:numel(labelNames)
        pieLabels = cat(1, pieLabels,...
            [num2str(typeTable.NumSynapses(i)), ' - ', typeTable.Label{i}]);
    end

    figure();
    p = pie(typeTable.NumSynapses);
    addTitleToPieChart(gca, ['c', num2str(neuron.ID), ' ', synapseName, ' Synapses by Presynaptic Neuron Type']);
    set(findall(p, 'Type', 'text'), 'FontSize', 12);
    legend(pieLabels, 'Location', 'eastoutside');
    colormap(othercolor('Spectral10', numel(pieLabels)));
