function T = networkTable(neuron)
	% generate an easy to read network table
	%
	% 18Jul2017 - SSP - created

	eT = neuron.conData.edgeTable;
	nT = neuron.conData.nodeTable;
	nodeN = nT.CellID;


	% contacts -> labels, indices
	SourceLabel = cell(1,1);
	TargetLabel = cell(1,1);
	SourceInd = [];
	TargetInd = [];
	included = [];


	% skip one per for undirected
	skipNext = false;

	for ii = 1:size(neuron.conData.edgeTable);
		if skipNext
			skipNext = false;
		else
			included = cat(1, included, ii);
			SourceInd = cat(1, SourceInd, find(nodeN == eT.Source(ii)));
			TargetInd = cat(1, TargetInd, find(nodeN == eT.Target(ii)));

			sl = nT.NodeTag(SourceInd(end));
			if ~any(isletter(char(sl)))
				SourceLabel = cat(1, SourceLabel, '-');
			else
				SourceLabel = cat(1, SourceLabel, sl);
			end

			tl = nT.NodeTag(TargetInd(end));
			if ~any(isletter(char(tl)))
				TargetLabel = cat(1, TargetLabel, '-');
			else
				TargetLabel = cat(1, TargetLabel, tl);
			end

			if ~eT.Dir(ii)
				skipNext = true;
			end
		end
	end

	TargetLabel(1,:) = [];
	SourceLabel(1,:) = [];

	T = table(SourceInd, TargetInd, eT.Weight(included),... 
		SourceLabel, TargetLabel, eT.LocalName(included),... 
		eT.Dir(included), eT.Source(included), eT.Target(included),...
		'VariableNames', {'A', 'B', 'N',... 
		'A_name', 'B_name', 'Synapse',... 
		'Dir', 'A_num', 'B_num'});

	fprintf('removed %u undirected partners\n', size(eT, 1) - length(included))