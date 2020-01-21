function T = countLinkedNeurons(linkedIDs, synapseName)
% COUNTLINKEDNEURONS
%
% Syntax:
%   T = countLinkedNeurons(linkedIDs, synapseName)
%
% Inputs:
%   linkedIDs               Neuron object or table or array of linkedIDs
% Optional inputs:
%   synapseName             If using Neuron input, specify synapse name
%
% Outputs:
%   T                       Table with 2 columns: IDs and # of synapses
%
% Examples:
%   c1441 = Neuron(1441, 'i', true);
%   % Option 1
%   T = countLinkedNeurons(c1441, 'RibbonPost');
%   % Option 2
%   c1441_synapses = getLinkedNeurons(c1441, 'RibbonPost');
%   T = countLinkedNeurons(c1441_synapses);
%
% History:
%   4Nov2019 - SSP
% -------------------------------------------------------------------------

    if nargin == 2
        if isa(linkedIDs, 'sbfsem.core.NeuronAPI')
            neuron = linkedIDs;
            if isempty(neuron.links)
                [linkedIDs, ~] = getLinkedNeurons(linkedIDs, synapseName);
            else
                linkedIDs = neuron.links{strcmp(neuron.links.SynapseType, synapseName), 'NeuronID'};
            end
        elseif istable(linkedIDs)
            linkedIDs = linkedIDs{strcmp(linkedIDs.SynapseType, synapseName), 'NeuronID'};
        end
    elseif nargin == 1
        if istable(linkedIDs)
            linkedIDs = linkedIDs{:, 'NeuronID'};
        end
    end

    linkedIDs(isnan(linkedIDs)) = 0;
    
    % Group by linked neuron ID
    [groupIndex, groupNames] = findgroups(linkedIDs);
    n = splitapply(@numel, linkedIDs, groupIndex);

    % Sort linked neurons by number of synapses
    [n, ind] = sort(n, 'descend');
    groupNames = groupNames(ind);

    T = table(groupNames, n, 'VariableNames', {'NeuronID', 'Count'});