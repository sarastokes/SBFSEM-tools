function [handles, neuron] = populatePlotsOld(handles, neuron)
	% create GUI plots
	% 
	% 21Jun2017 - SSP - moved from methods
	% 5Jul2017 - SSP - rewrote for struct->table
    % 3Aug2017 - SSP - edits for NeuronApp class compatibility

	T = neuron.dataTable;
	sc = getStructureColors();

	% get soma location
	somaXYZ = getSomaXYZ(neuron);

	% throw out cell body and syn multi nodes
	rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
	% make a new table with only unique synapses
	synTable = T(rows, :);
	% group by LocalName
	[~, names] = findgroups(synTable.LocalName);
	% how many synapse types
	numSyn = numel(names);

	handles.numBins = zeros(2, numSyn);
	neuron.somaDist = cell(numSyn, 1);

	% plot the synapses
	for ii = 1:numSyn
		% synapse 3d plot
		xyz = getSynXYZ(T, names{ii});
		handles.lines(ii) = line('Parent', handles.ax.d3plot,...
			'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
			'Color', sc(names{ii}),...
			'Marker', '.', 'MarkerSize', 10,...
			'LineStyle', 'none');
		set(handles.lines(ii), 'Visible', 'off');

		% synapse distance histograms
		neuron.somaDist{ii,1} = fastEuclid3d(somaXYZ, xyz);
		[counts, bins] = histcounts(neuron.somaDist{ii,1});
		binInc = bins(2) - bins(1);
		cent = bins(1:end-1) + binInc/2;
		handles.somaBins(ii) = line('Parent', handles.ax.soma,...
			'XData', cent, 'YData', counts,...
			'Color', sc(names{ii}),...
			'LineWidth', 2);
		set(handles.somaBins(ii), 'Visible', 'off');
		handles.numBins(1,ii) = length(bins);
		% tableData = get(handles.synTable, 'Data');
		handles.synTable.Data{ii,5} = length(bins);

		% z-axis plot
		[counts, binCenters] = neuron.getHist(xyz(:,3));
		handles.zBins(ii) = line('Parent', handles.ax.z,...
			'XData', counts, 'YData', binCenters,...
			'Color', sc(names{ii}),...
			'LineWidth', 2);
		set(handles.zBins(ii), 'Visible', 'off');
		handles.numBins(2,ii) = length(binCenters + 1);
	end

		xlabel(handles.ax.z, 'synapse counts');
		ylabel(handles.ax.z, 'slice (z-axis)'); 
		xlabel(handles.ax.soma, 'distance from soma');
		ylabel(handles.ax.soma, 'synapse count');

	% plot the cell's skeleton
    skelRow = strcmp(T.LocalName, 'cell');
    xyz = table2array(T(skelRow, 'XYZum'));
    handles.skeletonLine = line('Parent', handles.ax.d3plot,...
    	'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
       	'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
       	'LineStyle', 'none');
    set(obj.handles.skeletonLine, 'Visible', 'off');

    % stratification histogram
    [counts, bins] = histcounts(xyz(:,3));
    binInc = bins(2) - bins(1);
    cent = bins(1:end-1) + binInc/2;
    handles.skeletonBins = line('Parent', obj.handles.ax.z,...
    	'XData', counts, 'YData', cent,...
    	'LineWidth', 2, 'Color', 'k',...
    	'Visible', 'off');
    set(handles.tx.skelBins, 'String', num2str(length(cent)));


    % plot the soma - keep it visible
    handles.somaLine = line('Parent', handles.ax.d3plot,...
    	'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

    xlabel(handles.ax.d3plot, 'x-axis');
    ylabel(handles.ax.d3plot, 'y-axis');
    zlabel(handles.ax.d3plot, 'z-axis');
end