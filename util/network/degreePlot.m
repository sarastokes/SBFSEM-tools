function p = degreePlot(neuron)
    % DEGREEPLOT
    %
    % Description:
    %   Plot graph representation of neuron connectivity
    %
    % Syntax:
    %   p = degreePlot(neuron, varargin)
    %
    % Inputs:
    %   neuron          Neuron object
    %   varargin        Key/value arguments passed to Matlab's graph/plot
    %
    % Note:
    %   Newer versions of MATLAB will plot 3D graph, older versions will
    %   plot a 2D layered graph
    %
    % History:
    %   8Jul2018 - SSP
    %   30Oct2018 - SSP - Renamed to degreePlot, moved to utils
    %   16Nov2018 - SSP - Added force3 plot option
    %   21Aug2019 - SSP - Moved into NeuronGraph
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'sbfsem.core.StructureAPI'), 'Input Neuron object');

    % Convert neuron to a graph
    [G, nodeIDs] = neuron.graph();
    
    p = neuronGraphPlot(neuron);
    
    highlight(p, find(G.degree == 1), 'NodeColor', 'g', 'MarkerSize', 1);
    highlight(p, find(G.degree == 2), 'MarkerSize', 0.05);
    highlight(p, find(G.degree == 3), 'MarkerSize', 1, 'NodeColor', 'r');
    