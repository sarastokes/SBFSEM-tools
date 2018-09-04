function synapseSphere(neuron, synapse, varargin)
    % SYNAPSESPHERE
    %
    % Description:
    %   Render a neuron's synapses as 3D spheres
    %
    % Syntax:
    %   synapseSphere(neuron, synapse, varargin);
    %
    % Inputs:
    %   neuron              Neuron object
    %   synapse             Synapse name or XYZ coordinates
    % Optional key/value inputs:
    %   ax                  Axes handle (default = new figure)
    %   sf                  Synapse size (default = 0.5)
    %   facecolor           Render color (default = red)
    %   edgecolor           Default = none
    %   facealpha           Render transparency (default = 1)
    %   tag                 Char to identify renders in scene
    %
    % Notes:
    %   A unit (1 micron) sphere is created and moved to the synapse XYZ
    %   location. The sphere is scaled by the synapse size factor.
    %
    % Examples:
    %   % Import neuron with synapses
    %   c6800 = Neuron(6800, 't', true);
    %   % Render (or export existing render from RenderApp)
    %   c6800.build(); c6800.render('FaceColor', [0, 0.3, 0.8]);
    %   % For a reminder of synapse names (use the "Detailed names"):
    %   c6800.printSyn();
    %   % Add synapses
    %   synapseSphere(c6800, 'ConvPre', 'ax', gca);
    %   synapseSphere(c6800, 'Unknown', 'ax', gca,...
    %       'FaceColor', [0.5 0.5 0.5], 'FaceAlpha', 0.5);
    % History:
    %   5Jan2018 - SSP
    %   28Feb2018 - SSP - Added synapse name to tag
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'NeuronAPI'), 'First argument must be neuron object');
    
    if isnumeric(synapse)
        xyz = synapse;
    else
        xyz = neuron.getSynapseXYZ(synapse);
    end
    
    ip = inputParser();
    ip.CaseSensitive = false;
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

    if isempty(ip.Results.Tag) && ~isnumeric(synapse)
        Tag = ['c', num2str(neuron.ID)];
        if ~isnumeric(synapse)
            Tag = [Tag, char(synapse)];
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