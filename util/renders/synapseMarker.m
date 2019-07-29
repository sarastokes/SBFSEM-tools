function synapseMarker(neuron, synapse, varargin)
	% SYNAPSEMARKER
	%
	% Syntax:
    %   synapseSphere(neuron, synapse, varargin);
    %
    % Inputs:
    %   neuron              Neuron object
    %   synapse             Synapse name or XYZ coordinates
    % Optional key/value inputs:
    %   ax                  Axes handle (default = new figure)
    % 	Marker 				Marker shape (default = 'o')
    %   FaceColor           Marker face color (default = none)
    %   EdgeColor           Marker edge color (default = red)
    %   Tag                 Char to identify renders in scene
    % Any other key/value input to the plot() command
    %
    % For more information on the other possible key/value inputs: 
    %	https://www.mathworks.com/help/matlab/ref/linespec.html
    % Marker Specifiers shows a list of possible 'Marker' inputs
    % Also helpful will be MarkerSize, LineWidth
    %
    % Examples:
    %	See help for synapseSphere.m for general usage.
    %
    % 	% Helpful properties to experiment with:
    %	synapseMarker(c5370, 'RibbonPost',...
    %		'Marker', 'x', 'LineWidth', 1);
    %
    % 	synapseMarker(c5370, 'ConvPost',...
    %		'MarkerSize', 7, 'FaceColor', [0 1 1], 'EdgeColor', 'k');
    %
	% See also:
	%	SYNAPSESPHERE
	%
	% History:
	%	20190416 - SSP 
    % ---------------------------------------------------------------------

	 assert(isa(neuron, 'sbfsem.core.NeuronAPI'),...
        'First argument must be Neuron object');
    
    if ~isnumeric(synapse)
        xyz = neuron.getSynapseXYZ(synapse);
    elseif size(synapse, 2) == 3
        xyz = synapse;
    elseif isequal(size(synapse(:), 1), numel(synapse))
        T = neuron.getSynapseNodes();
        row = ismember(T.ParentID, synapse);
        xyz = T{row, 'XYZum'};
    else
        error('synapseMarker:Unrecognized synapse');
    end

    ip = inputParser();
    ip.KeepUnmatched = true;  % Surf properties
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'Marker', 'o', @ischar);
    addParameter(ip, 'EdgeColor', 'r', @(x) ischar(x) || isvector(x));
    addParameter(ip, 'FaceColor', 'none', @(x) ischar(x) || isvector(x));
    addParameter(ip, 'Tag', [], @ischar);
    parse(ip, varargin{:});

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
        grid(ax, 'on');
    else
        ax = ip.Results.ax;
    end

    plot3(xyz(:, 1), xyz(:, 2), xyz(:, 3),...
    	'Parent', ax,...
    	'LineStyle', 'none',...
    	'Marker', ip.Results.Marker,...
    	'MarkerFaceColor', ip.Results.FaceColor,...
    	'MarkerEdgeColor', ip.Results.EdgeColor,...
    	'Tag', Tag, ip.Unmatched);