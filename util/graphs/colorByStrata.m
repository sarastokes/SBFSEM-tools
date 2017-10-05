function fh = colorByStrata(neuron)
	% COLORBYSTRATA

	xyz = neuron.dataTable.XYZum;
	z = xyz(:,3);
	ind = [round(min(z)), round(max(z))];

	co = pmkmp(ind(2)-ind(1) + 1, 'cubicl');
	fh = figure('Color', 'w',...
		'Name', 'Stratification Color Map');
	ax = axes('Parent', fh);
	hold(ax, 'on');
	for ii = 1:size(xyz, 1)
		cInd = round(xyz(ii,3))-ind(1)+1;
		plot(xyz(ii,1), xyz(ii,2),...
			'Marker', '.',...
			'Color', co(cInd,:),...
			'MarkerSize', 5);
	end
