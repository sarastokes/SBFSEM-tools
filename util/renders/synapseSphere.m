function synapseSphere(neuron, synapseName, varargin)
    % SYNAPSESPHERE
    %
    % Description:
    %   Render a neuron's synapses as 3D spheres
    %
    % Inputs:
    %   neuron              Neuron object
    %   synapseName         Synapse name or XYZ coordinates
    % Optional key/value inputs:
    %   ax                  Axes handle (default = new figure)
    %   sf                  Synapse size (default = 0.5)
    %   facecolor           Render color (default = red)
    %   edgecolor           Default = none
    %   facealpha           Render transparency (default = 1)
    %   tag                 Char to identify renders in scene
    %
    % Notes:
    %   A unit (1 micron) sphere is created and moved to the synapse XYZ l
    %   location. The sphere is scaled by the synapse size factor.
    %
    % History:
    %   5Jan2017 - SSP
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'Neuron'), 'First argument must be neuron object');
    
    if isnumeric(synapseName)
        xyz = synapseName;
    else
        xyz = neuron.getSynapseXYZ(synapseName);
    end
    
    ip = inputParser();
    ip.CaseSensitive = true;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'sf', 0.5, @isnumeric);
    addParameter(ip, 'EdgeColor', 'none',...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceColor', rgb('light red'),...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceAlpha', 1,...
        @(x) validateattributes(x, {'numeric'}, {'<',1, '>',0}));
    addParameter(ip, 'Tag', [], @ischar);
    parse(ip, varargin{:});

    if isempty(ip.Results.Tag) && ~isnumeric(synapseName)
        Tag = ['c', num2str(neuron.ID)];
        if isnumeric(synapseName)
            Tag = [Tag, char(synapseName)];
        end
    else
        Tag = ip.Results.Tag;
    end
    
    SF = ip.Results.sf;
    if isempty(ip.Results.ax)
        ax = axes('Parent', figure());
        hold on;
        axis(ax, 'equal');
        view(ax, 3);
        grid(ax, 'on');
        lightangle(225, 30);
        lightangle(45, 30);
    else
        ax = ip.Results.ax;
    end
    
    % Get the unit sphere
    [X, Y, Z] = sphere(21);
    % Scale by the synapse factor
    X = X*SF; Y = Y*SF; Z = Z*SF;
    
    for i = 1:size(xyz, 1)
        surf(X + xyz(i,1), Y + xyz(i,2), Z + xyz(i,3),...
            'Parent', ax,...
            'FaceColor', ip.Results.FaceColor,...
            'EdgeColor', ip.Results.EdgeColor,...
            'FaceAlpha', ip.Results.FaceAlpha,...
            'Tag', Tag);
    end