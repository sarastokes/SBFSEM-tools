function p = neuronGraphPlot(neuron, varargin)
    % NEURONGRAPHPLOT
    %
    % Description:
    %   Neuron graph representation with true XYZ coordinates
    %
    % Syntax:
    %   p = neuronGraphPlot(neuron, varargin)
    %
    % Inputs:
    %   neuron      Neuron object
    % Optional inputs:
    %   Key/value arguments for Matlab's graph/plot
    % 
    % Output:
    %   p           Graph plot handle
    %
    % Note:
    %   Newer versions of MATLAB will plot 3D graph, older versions will
    %   plot a 2D layered graph
    %
    % See also:
    %   DEGREEPLOT, NEURONGRAPH
    %
    % History:
    %   3Dec2018 - SSP - Moved from degreePlot
    %   19May2019 - SSP - Added zero value for annotations w/out locations
    %   21Aug2019 - SSP - Changed input options, moved to NeuronGraph
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.StructureAPI'), 'Input Neuron object');
    
    % Convert neuron to a graph
    [G, nodeIDs] = neuron.graph();

    figure('Name', sprintf('c%u graph plot', neuron.ID));
    try
        p = plot(G, 'layout', 'force3', varargin{:});
        xyz = [];
        for i = 1:numel(nodeIDs)
            iXYZ = neuron.nodes{neuron.nodes.ID == nodeIDs(i), 'XYZum'};
            if isempty(iXYZ)
                iXYZ = [0, 0, 0];
            end
            xyz = cat(1, xyz, iXYZ);
        end
        p.XData = xyz(:, 1); p.YData = xyz(:, 2); p.ZData = xyz(:, 3);
        hold on; grid on; axis equal tight;
    catch
        p = plot(G, 'layout', 'layered', varargin{:});
    end