function fh = colorBySomaDistance(neuron)
    % COLORBYSOMADISTANCE
    %
    % Description:
    %   Plot annotations colored by soma distance
    %
    % Syntax:
    %   fh = colorBySomaDistance(neuron)
    %
    % See also:
    %   COLORBYSTRATA, COLORBYUSER
    %
    % History:
    %   19Feb2022 - SSP
    %----------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input Neuron object');


	xyz = neuron.getCellXYZ();
    soma = neuron.getSomaXYZ();
    d = fastEuclid2d(soma(1:2), xyz(:, 1:2));

    co = pmkmp(numel(0:ceil(max(d))), 'CubicL');
	fh = figure('Color', 'w',...
		'Name', 'Soma Distance Color Map');
	ax = axes('Parent', fh);
	hold(ax, 'on');
    axis(ax, 'equal');
    grid(ax, 'on');

    for i = 1:size(xyz, 1)
        colorIndex = round(d(i)) + 1;
		plot(xyz(i,1), xyz(i,2),...
			'Marker', '.',...
			'Color', co(colorIndex,:),...
			'MarkerSize', 5,...
            'Tag', num2str(round(d(i), 2)));
    end

    caxis(ax, [0 ceil(max(d))]);
    colormap(ax, co);
    colorbar();



    

