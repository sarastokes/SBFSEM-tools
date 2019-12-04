function h = synapseMarker(neuron, synapse, varargin)
	% SYNAPSEMARKER
	%
	% Syntax:
    %   h = synapseSphere(neuron, synapse, varargin);
    %
    % Inputs:
    %   neuron              Neuron object
    %   synapse             Synapse name or XYZ coordinates
    % Optional key/value inputs:
    %   ax                  Axes handle (default = new figure)
    % 	Marker 				Marker shape (default = 'o')
    %   FaceColor           Marker face color (default = none)
    %   EdgeColor           Marker edge color (default = black)
    %   Tag                 Char to identify renders in scene
    % Any other key/value input to the plot() command
    % Output:
    %   h                   Handle to created graphics object
    %
    % Notes:
    %   For more information on the other possible key/value inputs: 
    %   	https://www.mathworks.com/help/matlab/ref/linespec.html
    %   Marker Specifiers shows a list of possible 'Marker' inputs
    %   MarkerSize and LineWidth are particularly helpful
    %
    % Examples:
    %	See help for synapseSphere.m for general usage.
    %
    % 	% Helpful properties to experiment with:
    %	synapseMarker(c5370, 'RibbonPost',...
    %		'Marker', 'x', 'LineWidth', 1);
    %
    % 	synapseMarker(c5370, 'ConvPost',...
    %		'MarkerSize', 7, 'FaceColor', [0 1 1], 'EdgeColor', 'r');
    %
	% See also:
	%	SYNAPSESPHERE
	%
	% History:
	%	16Apr2019 - SSP 
    %   1Oct2019 - SSP - added handle to graphics object as output
    %   2Dec2019 - SSP - Changed default edge color to black
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
    ip.KeepUnmatched = true;  % plot3 properties
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'Marker', 'o', @ischar);
    addParameter(ip, 'EdgeColor', 'k', @(x) ischar(x) || isvector(x));
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
        hold(ax, 'on');
        axis(ax, 'equal');
        grid(ax, 'on');
    else
        ax = ip.Results.ax;
    end

    h = plot3(xyz(:, 1), xyz(:, 2), xyz(:, 3),...
    	'Parent', ax,...
    	'LineStyle', 'none',...
    	'Marker', ip.Results.Marker,...
    	'MarkerFaceColor', ip.Results.FaceColor,...
    	'MarkerEdgeColor', ip.Results.EdgeColor,...
    	'Tag', Tag, ip.Unmatched);