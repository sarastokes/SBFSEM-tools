classdef ClassifyH1H2 < HorizontalCells

methods
	function obj = ClassifyH1H2(neuron)
		% add analyses to HorizontalCells dataTable
		T = obj.makeRows(neuron);
		T = [T, obj.analyzeRows(neuron)];
		obj.dataTable = [obj.dataTable, T];
	end

	function T = analyzeRows(obj, neuron)
		% ANALYZEROWS
		d = dendriteSize(neuron, [0.5 2]);
		T = table({d.median, d.avg, d.sem, d.n, d.wind});
		T.Properties.VariableNames = {'Median', 'Mean', 'SEM', 'N', 'Window'};
	end % analyzeRows

end % methods
end % classdef


	