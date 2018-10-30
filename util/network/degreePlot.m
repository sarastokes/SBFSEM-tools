function p = degreePlot(neuron)
    % CONNECTIVITYVIEW
    %
    % Description:
    %   Plot neuron connectivity with connections 
    %
    % Syntax:
    %   p = degreePlot(neuron)
    %
    % History:
    %   8Jul2018 - SSP
    %   30Oct2018 - SSP - Renamed to degreePlot, moved to utils
    % ---------------------------------------------------------------------
    [G, ~] = neuron.graph();
    figure();
    p = plot(G, 'layout', 'layered');
    highlight(p, find(G.degree == 1),...
        'NodeColor', 'g', 'MarkerSize', 1);
    highlight(p, find(G.degree == 2),...
        'MarkerSize', 0.05);
    highlight(p, find(G.degree == 3),...
        'MarkerSize', 0.5, 'NodeColor', 'r');
    