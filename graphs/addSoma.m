function addSoma(cellData, axHandle, whichDim)
	% add the soma to an existing synapse plot


	if ~isstruct(cellData)
		error('input structure from parseCellData.m');
	elseif ~ishandle(axHandle)
		error('input axesHandle!');
	end
		
	gca = axHandle; hold on;

	d = cellData.props.sizeMap(cellData.somaNode);
	xyz = cellData.props.xyzMap(cellData.somaNode);

	if length(whichDim) == 3
		plot3(xyz(1), xyz(2), xyz(3), '*k', 'MarkerSize', 12);
	else
		ind = find('XYZ', whichDim);
		plot(xyz(ind(1)), xyz(ind(2)), '*k', 'MarkerSize', 12);
	end
