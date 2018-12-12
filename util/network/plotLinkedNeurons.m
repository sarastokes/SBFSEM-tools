function h = plotLinkedNeurons(linkedIDs)
    % PLOTLINKEDNEURONS
    %
    % Description:
    %   Plot pie chart of number of synapses per linked neuron
    %
    % Syntax:
    %   h = plotLinkedNeurons(linkedIDs);
    %
    % Input:
    %   linkedIDs       array or table of linked IDs from getLinkedNeurons
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

    if istable(linkedIDs)
        linkedIDs = linkedIDs{:, 1};
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
    
    
