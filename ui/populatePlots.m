function obj = populatePlots(obj)
	% create GUI plots
	% 
	% 21Jun2017 - SSP - moved from methods

	sc = getStructureColors();
	somaXYZ = obj.nodeData.xyzMap(obj.somaNode);
	numSyn = length(obj.synData.names);
	obj.handles.numBins = zeros(2, numSyn);
	obj.somaDist = cell(numSyn, 1);
	% plot the synapses
	for ii = 1:numSyn
		% synapse 3d plot
		synDir = getSynNodes(obj.synData, obj.synData.names{ii});
		xyz = getDim(obj.nodeData, synDir, 'XYZ');
		obj.handles.lines(ii) = line('Parent', obj.handles.ax.d3plot,...
			'XData', xyz(1,:), 'YData', xyz(2,:), 'ZData', xyz(3,:),...
			'Color', sc(obj.synData.names{ii}),...
			'Marker', '.', 'MarkerSize', 10,...
			'LineStyle', 'none');
		set(obj.handles.lines(ii), 'Visible', 'off');

		% synapse distance histograms
		obj.somaDist{ii,1} = FastEuclid3d(somaXYZ, xyz');
		[counts, bins] = histcounts(obj.somaDist{ii,1});
		binInc = bins(2) - bins(1);
		cent = bins(1:end-1) + binInc/2;
		obj.handles.somaBins(ii) = line('Parent', obj.handles.ax.soma,...
			'XData', cent, 'YData', counts,...
			'Color', sc(obj.synData.names{ii}),...
			'LineWidth', 2);
		set(obj.handles.somaBins(ii), 'Visible', 'off');
		xlabel(obj.handles.ax.soma, 'distance from soma');
		ylabel(obj.handles.ax.soma, 'synapse count');
		obj.handles.numBins(1,ii) = length(bins);
		tableData = get(obj.handles.synTable, 'Data');
		obj.handles.synTable.Data{ii,5} = length(bins);

		% z-axis plot
		[counts binCenters] = obj.getHist(xyz(3,:));
		obj.handles.zBins(ii) = line('Parent', obj.handles.ax.z,...
			'XData', binCenters, 'YData', counts,...
			'Color', sc(obj.synData.names{ii}),...
			'LineWidth', 2);
		set(obj.handles.zBins(ii), 'Visible', 'off');
		xlabel(obj.handles.ax.z, 'slice (z-axis)'); 
		ylabel(obj.handles.ax.z, 'synapse counts');
		obj.handles.numBins(2,ii) = length(binCenters + 1);
	end


	% plot the cell's skeleton
	xyz = [];
	for ii = 1:length(obj.skeleton)
    	if ~isempty(obj.skeleton{1,ii})
    		xyz = [xyz; obj.nodeData.xyzMap(obj.skeleton{1,ii})];
    	end
    end
    obj.handles.skeletonLine = line('Parent', obj.handles.ax.d3plot,...
    	'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
       	'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
       	'LineStyle', 'none');
    set(obj.handles.skeletonLine, 'Visible', 'off');

    % plot the soma - keep it visible
    obj.handles.somaLine = line('Parent', obj.handles.ax.d3plot,...
    	'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

    xlabel(obj.handles.ax.d3plot, 'x-axis');
    ylabel(obj.handles.ax.d3plot, 'y-axis');
    zlabel(obj.handles.ax.d3plot, 'z-axis');
end