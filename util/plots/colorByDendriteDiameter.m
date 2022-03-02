function fh = colorByDendriteDiameter(neuron, percentSoma)
    % COLORBYDENDRITEDIAMETER
    %
    % Description:
    %   Plot annotations colored by soma distance
    %
    % Syntax:
    %   fh = colorByDendriteDiameter(neuron, percentSoma)
    %
    % See also:
    %   COLORBYSTRATA, COLORBYUSER, COLORBYSOMADISTANCE
    %
    % History:
    %   20Feb2022 - SSP
    %   24Feb2022 - SSP - Option to specify soma cutoff value
    %----------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input Neuron object');
    if nargin < 2
        percentSoma = 0.5;
    end
    nodes = neuron.getCellNodes();
    somaRadius = neuron.getSomaSize(false);
    nodes(nodes.Rum > percentSoma*somaRadius, :) = [];
	

    co = pmkmp(100, 'CubicL');
	fh = figure('Color', 'w',...
		'Name', 'Dendrite Diameter Color Map');
	ax = axes('Parent', fh);
	hold(ax, 'on');
    axis(ax, 'equal');
    grid(ax, 'on');

    for i = 1:size(nodes.XYZum, 1)
        colorIndex = ceil(nodes.Rum(i) / (max(nodes.Rum/100)));
		plot3(nodes.XYZum(i,1), nodes.XYZum(i,2), nodes.XYZum(i,3),...
			'Marker', '.',...
			'Color', co(colorIndex,:),...
			'MarkerSize', 5,...
            'Tag', num2str(round(nodes.Rum(i), 2)));
    end

    caxis(ax, [0 max(nodes.Rum)]);
    colormap(ax, co);
    colorbar();



    

