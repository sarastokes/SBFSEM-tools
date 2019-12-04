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
    %   ax          Parent axes handle
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
    %   18Nov2019 - SSP - Added option for parent axes handle input
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.StructureAPI'), 'Input Neuron object');
    
    ip = inputParser();
    ip.CaseSensitive = false;
    ip.KeepUnmatched = true;
    addParameter(ip, 'ax', [], @ishandle);
    parse(ip, varargin{:});
    if isempty(ip.Results.ax)
        ax = axes('Parent', figure('Name', sprintf('c%u graph plot', neuron.ID)));
        axis(ax, 'equal'); grid(ax, 'on');
    else
        ax = ip.Results.ax;
    end
    hold(ax, 'on');
    
    % Convert neuron to a graph
    [G, nodeIDs] = neuron.graph();

    try
        p = plot(ax, G, 'Layout', 'force3');
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
        p = plot(ax, G, 'Layout', 'layered');
    end