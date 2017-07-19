function obj = populatePlots(obj)
	% create GUI plots
	% 
	% 21Jun2017 - SSP - moved from methods
	% 5Jul2017 - SSP - rewrote for struct->table

	T = obj.dataTable;
	sc = getStructureColors();

	% get soma location
	somaXYZ = getSomaXYZ(obj);

	% throw out cell body and syn multi nodes
	rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
	% make a new table with only unique synapses
	synTable = T(rows, :);
	% group by LocalName
	[G, names] = findgroups(synTable.LocalName);
	% how many synapse types
	numSyn = numel(names);

	obj.handles.numBins = zeros(2, numSyn);
	obj.somaDist = cell(numSyn, 1);

	% plot the synapses
	for ii = 1:numSyn
		% synapse 3d plot
		xyz = getSynXYZ(T, names{ii});
		obj.handles.lines(ii) = line('Parent', obj.handles.ax.d3plot,...
			'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
			'Color', sc(names{ii}),...
			'Marker', '.', 'MarkerSize', 10,...
			'LineStyle', 'none');
		set(obj.handles.lines(ii), 'Visible', 'off');

		% synapse distance histograms
		obj.somaDist{ii,1} = fastEuclid3d(somaXYZ, xyz);
		[counts, bins] = histcounts(obj.somaDist{ii,1});
		binInc = bins(2) - bins(1);
		cent = bins(1:end-1) + binInc/2;
		obj.handles.somaBins(ii) = line('Parent', obj.handles.ax.soma,...
			'XData', cent, 'YData', counts,...
			'Color', sc(names{ii}),...
			'LineWidth', 2);
		set(obj.handles.somaBins(ii), 'Visible', 'off');
		obj.handles.numBins(1,ii) = length(bins);
		tableData = get(obj.handles.synTable, 'Data');
		obj.handles.synTable.Data{ii,5} = length(bins);

		% z-axis plot
		[counts, binCenters] = obj.getHist(xyz(:,3));
		obj.handles.zBins(ii) = line('Parent', obj.handles.ax.z,...
			'XData', counts, 'YData', binCenters,...
			'Color', sc(names{ii}),...
			'LineWidth', 2);
		set(obj.handles.zBins(ii), 'Visible', 'off');
		obj.handles.numBins(2,ii) = length(binCenters + 1);
	end

		xlabel(obj.handles.ax.z, 'synapse counts');
		ylabel(obj.handles.ax.z, 'slice (z-axis)'); 
		xlabel(obj.handles.ax.soma, 'distance from soma');
		ylabel(obj.handles.ax.soma, 'synapse count');

	% plot the cell's skeleton
    skelRow = strcmp(T.LocalName, 'cell');
    xyz = table2array(T(skelRow, 'XYZum'));
    obj.handles.skeletonLine = line('Parent', obj.handles.ax.d3plot,...
    	'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
       	'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
       	'LineStyle', 'none');
    set(obj.handles.skeletonLine, 'Visible', 'off');

    % stratification histogram
    [counts, bins] = histcounts(xyz(:,3));
    binInc = bins(2) - bins(1);
    cent = bins(1:end-1) + binInc/2;
    obj.handles.skeletonBins = line('Parent', obj.handles.ax.z,...
    	'XData', counts, 'YData', cent,...
    	'LineWidth', 2, 'Color', 'k',...
    	'Visible', 'off');


    % plot the soma - keep it visible
    obj.handles.somaLine = line('Parent', obj.handles.ax.d3plot,...
    	'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

    xlabel(obj.handles.ax.d3plot, 'x-axis');
    ylabel(obj.handles.ax.d3plot, 'y-axis');
    zlabel(obj.handles.ax.d3plot, 'z-axis');
end