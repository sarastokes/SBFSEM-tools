function p = plotPathLength(neuron)
    % PLOTPATHLENGTH
    %
    % Description:
    %   Plot graph of neuron with nodes colored by distance (in arbitrary
    %   units) from the soma.
    %
    % Syntax:
    %   p = plotPathLength(neuron);
    %
    % Input:
    %   neuron              Neuron object
    % Output:
    %   p                   GraphPlot object
    %
    % See also:
    %   GRAPH/DISTANCES, GRAPH/PLOT, NEURONGRAPHPLOT
    %
    % History:
    %   19May2019 - SSP
    % ---------------------------------------------------------------------

    [G, nodeIDs] = graph(neuron);
    D = distances(G);
    G.Nodes.NodeColors = D(:,1);
    
    p = neuronGraphPlot(neuron, G, nodeIDs);
    p.NodeCData = G.Nodes.NodeColors;
    p.LineStyle = 'none';
    
    axis equal; colorbar(); view(2);
    
    colormap(flipud(haxby));
end