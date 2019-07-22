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
    %   synapse             Synapse name, ID or XYZ coordinates
    % Optional key/value inputs:
    %   ax                  Axes handle (default = new figure)
    %   sf                  Synapse size (default = 0.5)
    %   facecolor           Render color (default = red)
    %   edgecolor           Default = none
    %   facealpha           Render transparency (default = 1)
    %   tag                 Char to identify renders in scene
    % Any other key/value input to the surf() command that renders synapse
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
    %
    % See also:
    %   SYNAPSEMARKER
    %
    % History:
    %   5Jan2018 - SSP
    %   28Feb2018 - SSP - Added synapse name to tag
    %   
    % ---------------------------------------------------------------------
    
    assert(isa(neuron, 'sbfsem.core.NeuronAPI'),...
        'First argument must be Neuron object');
    
    if ~isnumeric(synapse)
        xyz = neuron.getSynapseXYZ(synapse);
    elseif isequal(size(synapse(:), 1), numel(synapse))
        T = neuron.getSynapseNodes();
        row = ismember(T.ParentID, synapse);
        xyz = T{row, 'XYZum'};
    else
        xyz = synapse;
    end

    ip = inputParser();
    ip.KeepUnmatched = true;  % Surf properties
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'MarkerSize', [], @isnumeric);
    addParameter(ip, 'SF', 0.5, @isnumeric);  % for backwards compatibility
    % surf properties with defaults
    addParameter(ip, 'EdgeColor', 'none',...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceColor', rgb('light red'),...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceAlpha', 1,...
        @(x) validateattributes(x, {'numeric'}, {'<',1, '>',0}));
    addParameter(ip, 'Tag', [], @ischar);
    parse(ip, varargin{:});
        
    if isempty(ip.Results.MarkerSize)
        SF = ip.Results.SF;
    else
        SF = ip.Results.MarkerSize;
    end

    if isempty(ip.Results.Tag) 
        if isnumeric(synapse) && numel(synapse) == 1
            Tag = ['s', num2str(synapse(1))];
        else
            Tag = ['c', num2str(neuron.ID)];
        end
    else
        Tag = ip.Results.Tag;
    end
    
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
            'Tag', Tag, ip.Unmatched);
    end