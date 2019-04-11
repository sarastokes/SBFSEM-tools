function ax = golgi(neuron, varargin)
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
    % Optional key/value inputs:
    %   ax          Handle to existing axes (default = new figure)
    %   invert      Invert colors (default = false)
    %
    % Outputs:
    %   ax          Handle to axes 
    %
    % History:
    %   10Feb2019 - SSP
    %   5Apr2019 - SSP - Added invert figure option, input parsing
    % ---------------------------------------------------------------------

    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'Ax', axes('Parent', figure()), @ishandle);
    addParameter(ip, 'Invert', false, @islogical);
    parse(ip, varargin{:});
    
    invertFigure = ip.Results.Invert;
    ax = ip.Results.Ax;
    delete(findall(ax, 'Type', 'light'));
    
    if invertFigure
        ax.Color = 'k'; ax.Parent.Color = 'k';
    end
    
    hold(ax, 'on');
    
    if invertFigure
        neuron.render('ax', ax, 'FaceColor', 'w');
    else
        neuron.render('ax', ax, 'FaceColor', 'k');
    end
    
    view(ax, 0, 90);
    hideAxes();
    