function obj = populatePlots(obj)
	% create GUI plots
	% 
	% 21Jun2017 - SSP - moved from methods

	% sc = getStructureColors();
	% somaXYZ = nodeData.xyzMap(somaNode);
	% numSyn = length(synData.names);
	% somaDist = cell(numSyn);

	% for ii = 1:numSyn
	% 	% synapse 3d plot
	% 	synDir = getSynNodes(synData, synData.names{ii});
	% 	xyz = getDim(nodeData, synDir, 'XYZ');
	% 	handles.lines(ii) = line('Parent', handles.ax,...
	% 		'XData', xyz(1,:), 'YData', xyz(2,:), 'ZData', xyz(3,:),...
	% 		'Color', sc(synData.names{ii}),...
	% 		'Marker', '.', 'MarkerSize', 10,...
	% 		'LineStyle', 'none', 'Visible', 'off');

	% 	% synapse distance histograms
	% 	somaDist{ii,1} = FastEuclid3d(somaXYZ, xyz');
	% 	[counts, bins] = histcounts(somaDist{ii,1});
	% 	binInc = bins(2) - bins(1);
	% 	cent = bins(1 : end-1) + binInc/2;
	% 	handles.somaBins(ii) = line('Parent', handles.barOne,...
	% 		'XData', cent, 'YData', counts,...
	% 		'Color', sc(synData.names{ii}),...
	% 		'LineWidth', 2);
	% 	set(handles.somaBins(ii), 'Visible', 'off');
	% 	xlabel(handles.barOne, 'distance from soma');
	% 	ylabel(handles.barOne, 'synapse count');
	% 	handles.numBins.somaDist = length(bins);
	% 	tableData = get(handles.synTable, 'Data');
	% 	handles.synTable.Data{ii,5} = handles.numBins.somaDist;
	% end

	% % skeleton
	% xyz = [];
	% for ii = 1:length(skeleton)


		sc = getStructureColors();
		somaXYZ = obj.nodeData.xyzMap(obj.somaNode);
		numSyn = length(obj.synData.names);
		obj.somaDist = cell(numSyn, 1);
		% plot the synapses
		for ii = 1:numSyn
			% synapse 3d plot
			synDir = getSynNodes(obj.synData, obj.synData.names{ii});
			xyz = getDim(obj.nodeData, synDir, 'XYZ');
			obj.handles.lines(ii) = line('Parent', obj.handles.ax,...
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
			obj.handles.somaBins(ii) = line('Parent', obj.handles.barOne,...
				'XData', cent, 'YData', counts,...
				'Color', sc(obj.synData.names{ii}),...
				'LineWidth', 2);
			set(obj.handles.somaBins(ii), 'Visible', 'off');
			xlabel(obj.handles.barOne, 'distance from soma');
			ylabel(obj.handles.barOne, 'synapse count');
			obj.handles.numBins.somaDist = length(bins);
			tableData = get(obj.handles.synTable, 'Data');
			obj.handles.synTable.Data{ii,5} = obj.handles.numBins.somaDist;

			% set(obj.handles.tx.somaBin,... 
			% 	'String', sprintf('Bins = %u', obj.handles.numBins.somaDist));

			% [counts bins] = histcounts(xyz(:,3));
			% binInc = bins(2) - bins(1);
			% cent = bins(1:end-1) + binInc/2;
			% obj.handles.zBins(ii) = line('Parent', obj.handles.zBar,...
			% 	'XData', cent, 'YData', counts,...
			% 	'Color', sc(obj.synData.names{ii}),...
			% 	'LineWidth', 2);
			% set(obj.handles.zBins(ii), 'Visible', 'off');
			% xlabel(obj.handles.zBar, 'z-axis'); 
			% ylabel(obj.handles.zBar, 'synapse counts');
			% obj.handles.numBins.z = length(bins);
		end


		% plot the cell's skeleton
		xyz = [];
		for ii = 1:length(obj.skeleton)
	    	if ~isempty(obj.skeleton{1,ii})
	    		xyz = [xyz; obj.nodeData.xyzMap(obj.skeleton{1,ii})];
	    	end
	    end
	    obj.handles.skeletonLine = line('Parent', obj.handles.ax,...
	    	'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
	       	'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
	       	'LineStyle', 'none');
	    set(obj.handles.skeletonLine, 'Visible', 'off');

	    % plot the soma - keep it visible
	    obj.handles.somaLine = line('Parent', obj.handles.ax,...
	    	'XData', somaXYZ(1), 'YData', somaXYZ(2), 'ZData', somaXYZ(3),...
	    	'Marker', '.', 'MarkerSize', 20, 'Color', 'k');

	    xlabel(obj.handles.ax, 'X Coordinate');
	    ylabel(obj.handles.ax, 'Y Coordinate');
	    zlabel(obj.handles.ax, 'Z Coordinate');
	end % populatePlot