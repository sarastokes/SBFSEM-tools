function p = ConnectivityView(neuron)
    % CONNECTIVITYVIEW
    %
    % Description:
    %   Plot neuron connectivity
    %
    % Syntax:
    %   p = ConnectivityView(neuron)
    %
    % History:
    %   8Jul2018 - SSP
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
    