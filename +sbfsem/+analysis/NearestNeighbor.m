classdef NearestNeighbor < sbfsem.analysis.NeuronAnalysis

	properties (Constant = true, Hidden = true)
		DisplayName = 'NearestNeighbor';
	end

	methods
		function obj = NearestNeighbor(neurons)
			obj@sbfsem.analysis.NeuronAnalysis(neurons);
			obj.doAnalysis();
		end

		function doAnalysis(obj, k)
			if nargin < 2
				k = 3;
			end

			% Get the soma location
           	[somaSizes, validIDs] = obj.somaDiameter(true);
			[ind, dst] = knnsearch(xyz, xyz, 'K', k);
		end

		function visualize(obj)
			figure('Name', 'knnsearch result');
			barh(dst(:,2:k), 'stacked');
			set(gca, 'YTickLabel', lbl, 'Box', 'off');
		end
	end
end