function h = plotLinkedNeurons(linkedIDs, synapseName)
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
    %   GETLINKEDNEURONS
    %
    % History:
    %   8Dec2018 - SSP
    % ---------------------------------------------------------------------

    if nargin == 2
        assert(isa(linkedIDs, 'sbfsem.core.NeuronAPI'), 'Input a Neuron object');
        [linkedIDs, ~] = getLinkedNeurons(linkedIDs, synapseName);
    else
        if istable(linkedIDs)
            linkedIDs = linkedIDs{:, 1};
        end
    end
    
    linkedIDs(isnan(linkedIDs)) = 0;
    
    [groupIndex, groupNames] = findgroups(linkedIDs);
    n = splitapply(@numel, linkedIDs, groupIndex);
    
    [n, ind] = sort(n, 'descend');
    groupNames = groupNames(ind);
    
    h = figure();
    pie(n, ones(size(n)), string(groupNames));
    
    % Quick hack to set unidentified neurons to white, if most numerous
    if groupNames(1) == 0
        colormap(flipud(haxby(256)));
    end
    
    
