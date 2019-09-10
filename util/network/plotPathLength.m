function p = plotPathLength(neuron, useDistance)
    % PLOTPATHLENGTH
    %
    % Description:
    %   Plot graph of neuron with nodes colored by distance from the soma,
    %   either in microns or arbitrary units
    %
    % Syntax:
    %   p = plotPathLength(neuron);
    %
    % Input:
    %   neuron              Neuron object
    %   useDistance         Calculate distance b/w nodes (default = true)
    % Output:
    %   p                   GraphPlot object
    %
    % See also:
    %   GRAPH/DISTANCES, GRAPH/PLOT, NEURONGRAPHPLOT
    %
    % History:
    %   19May2019 - SSP
    %   25May2019 - SSP - Added distance between nodes calculation
    % ---------------------------------------------------------------------

    if nargin < 2
        useDistance = true;
    end
    
    [G, nodeIDs] = neuron.graph('Weighted', useDistance);
    disp('Calculating distances...');
    D = distances(G);
    G.Nodes.NodeColors = D(:,1);
    
    disp('Plotting neuron graph...');
    p = neuronGraphPlot(neuron);
    p.NodeCData = G.Nodes.NodeColors;
    p.LineStyle = 'none';
    
    axis equal; colorbar(); view(2);
    
    colormap(flipud(haxby));
end