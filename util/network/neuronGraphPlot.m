function p = neuronGraphPlot(neuron, G, nodeIDs)
    % NEURONGRAPHPLOT
    %
    % Description:
    %   Neuron graph representation with true XYZ coordinates
    %
    % Syntax:
    %   p = neuronGraphPlot(neuron, G, nodeIDs)
    %
    % Inputs:
    %   neuron      Neuron object
    % Optional inputs:
    %   G           Graph representation of Neuron
    %   nodeIDs     List relating location ID to node ID
    % 
    % Output:
    %   p           Graph plot handle
    %
    % Note:
    %   Newer versions of MATLAB will plot 3D graph, older versions will
    %   plot a 2D layered graph
    %
    % See also:
    %   DEGREEPLOT, NEURON/GRAPH
    %
    % History:
    %   3Dec2018 - SSP - Moved from degreePlot
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.StructureAPI'), 'Input Neuron object');
    
    % Convert neuron to a graph
    if nargin < 3
        [G, nodeIDs] = neuron.graph();
    end

    figure('Name', sprintf('c%u graph plot', neuron.ID));
    try
        p = plot(G, 'layout', 'force3');
        xyz = [];
        for i = 1:numel(nodeIDs)
            xyz = cat(1, xyz,...
                neuron.nodes{neuron.nodes.ID == nodeIDs(i), 'XYZum'});
        end
        p.XData = xyz(:, 1); p.YData = xyz(:, 2); p.ZData = xyz(:, 3);
        hold on; grid on; axis equal tight;
    catch
        p = plot(G, 'layout', 'layered');
    end