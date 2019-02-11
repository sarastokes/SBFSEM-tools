function ax = golgi(neuron, ax)
    % GOLGI
    %
    % Description:
    %   Plot a neuron in a golgi-like flatmount
    %
    % Syntax:
    %   ax = golgi(neuron, ax)
    %
    % Inputs:
    %   neuron      Neuron object
    % Optional inputs:
    %   ax          Handle to existing axes (default = new figure)
    %
    % Outputs:
    %   ax          Handle to axes
    %
    % History:
    %   10Feb2019 - SSP
    % ---------------------------------------------------------------------
    
    if nargin < 2
        ax = axes('Parent', figure());
    else
        delete(findall(ax, 'Type', 'light'));
    end
    hold(ax, 'on');
    
    neuron.render('ax', ax, 'FaceColor', 'k');
    view(ax, 0, 90);
    hideAxes();
    