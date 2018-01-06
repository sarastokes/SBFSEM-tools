function synapseSphere(neuron, synapseName, varargin)
    % SYNAPSESPHERE
    %
    % History:
    %   5Jan2017 - SSP
    % ---------------------------------------------------------------------
    ip = inputParser();
    ip.CaseSensitive = true;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'sf', 2, @isnumeric);
    addParameter(ip, 'EdgeColor', 'none',...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceColor', rgb('light red'),...
        @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceAlpha', 1,...
        @(x) validateattributes(x, {'numeric'}, {'<',1, '>',0}));
    
    parse(ip, varargin{:});
    
    SF = ip.Results.sf;
    if isempty(ip.Results.ax)
        ax = axes('Parent', figure());
        hold on;
        axis equal;
        lightangle(225, 30);
        lightangle(45, 30);
    else
        ax = ip.Results.ax;
    end
    
    % Get the unit sphere
    [X, Y, Z] = sphere(21);
    
    if isnumeric(synapseName)
        xyz = synapseName;
    else
        xyz = neuron.getSynapseXYZ(synapseName);
    end
    
    for i = 1:size(xyz, 1)
        surf(ax, X/SF + xyz(i,1), Y/SF + xyz(i,2), Z/SF + xyz(i,3),...
            'FaceColor', ip.Results.FaceColor,...
            'EdgeColor', ip.Results.EdgeColor,...
            'FaceAlpha', ip.Results.FaceAlpha,...
            'Tag', ['c', num2str(neuron.ID), char(synapseName)]);
    end