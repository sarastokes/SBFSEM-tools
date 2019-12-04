function T = colorByUser(neuron)
    % COLORBYUSER
    %
    % History:
    %   20Aug2019 - SSP

    % Get the username data
    x = sbfsem.io.OData(neuron.source);
    [usernames, locationIDs] = x.getUsernames(neuron.ID);
    [groupIndex, groupNames] = findgroups(usernames);
    n = splitapply(@numel, usernames, groupIndex);

    [n, ind] = sort(n, 'descend');
    groupNames = groupNames(ind);

    % Plot the neuron graph
    [G, nodeIDs] = neuron.graph();
    p = neuronGraphPlot(neuron, 'Marker', '.', 'MarkerSize', 5);

    cmap = pmkmp(numel(ind), 'cubicl');

    for i = 1:numel(groupNames)
        userIDs = locationIDs(groupIndex == ind(i));
        highlight(p, find(ismember(nodeIDs, userIDs)),... 
            'NodeColor', cmap(ind(i),:));
    end