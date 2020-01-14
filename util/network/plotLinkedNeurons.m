function h = plotLinkedNeurons(linkedIDs, synapseName, printN)
    % PLOTLINKEDNEURONS
    %
    % Description:
    %   Plot pie chart of number of synapses per linked neuron
    %
    % Syntax:
    %   h = plotLinkedNeurons(linkedIDs);
    %   % Alternative input
    %   c1 = Neuron(1, 'i', true);
    %   h = plotLinkedNeurons(c1, 'RibbonPost');
    %
    % Input:
    %   linkedIDs       array or table of linked IDs from getLinkedNeurons
    % Alternative input:
    %   linkedIDs       Neuron object
    %   synapseName     Synapse name
    %
    % Notes:
    %    '0' indicates no linked neuron.
    %
    % See also:
    %   GETLINKEDNEURONS, GETALLLINKEDNEURONS
    %
    % History:
    %   8Dec2018 - SSP
    %   14Jan2020 - SSP - Added compatibility w/ neuron links property
    % ---------------------------------------------------------------------

    if nargin < 3
        printN = true;
    end
    
    if nargin == 2
        assert(isa(linkedIDs, 'Neuron'), 'Input a Neuron object');
        neuron = linkedIDs;
        str = ['c', num2str(neuron.ID), ' - '];
        if isempty(neuron.links)
            [linkedIDs, ~] = getLinkedNeurons(neuron, synapseName);
        else
            linkedIDs = neuron.links{strcmp(neuron.links.SynapseType, synapseName), 'NeuronID'};
        end
    elseif nargin == 1
        str = ''; synapseName = '';
        if istable(linkedIDs)
            linkedIDs = linkedIDs{:, 'NeuronID'};
        end
    end
    
    linkedIDs(isnan(linkedIDs)) = 0;
    
    [groupIndex, groupNames] = findgroups(linkedIDs);
    n = splitapply(@numel, linkedIDs, groupIndex);
    
    [n, ind] = sort(n, 'descend');
    groupNames = groupNames(ind);
    
    ax = axes('Parent', figure());
    pie(n, ones(size(n)), string(groupNames));
    
    % Quick hack to set unidentified neurons to white, if most numerous
    if groupNames(1) == 0
        colormap(flipud(haxby(256)));
    end

    h = title(ax, [str, synapseName, ' (n = ', num2str(numel(n)), ')']);
        %sprintf('%s - (n = %u)', synapseName, numel(n)));
    % Title always overlaps with labels
    ax.Position(2) = ax.Position(2) - 0.05;
    h.Position(2) = h.Position(2) + 0.1;
    
    if printN
        fprintf('Total synapses = %u\n', sum(n));
        for i = 1:numel(groupNames)
            fprintf('\t%u - %u\n', groupNames(i), n(i));
        end
    end
    
