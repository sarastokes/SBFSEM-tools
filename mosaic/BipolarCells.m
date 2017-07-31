classdef BipolarCells < Mosaic

methods
function obj = BipolarCells(Neuron)
	if ~strcmp(Neuron.cellData.cellType, 'bipolar cell')
		error('input cellType should be a bipolar cell');
	end
	T = obj.makeRows(Neuron);
	obj.dataTable = T;
end

function T = makeRows(obj, Neuron)
	% find the row matching the somaNode uuid
	row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
	% get xyzr values
	xyz = table2array(Neuron.dataTable(row, 'XYZum'));
	r = Neuron.dataTable{row, 'Size'} / 2;

	pol = obj.polStr(Neuron);

	pr = obj.coneStr(Neuron);
	n = obj.cellNameStr(Neuron);

	ribbons = nnz(strcmp(Neuron.dataTable.LocalName, 'ribbon pre') & Neuron.dataTable.Unique);
	
	C = {Neuron.cellData.cellNum, pr, pol, n, ribbons, xyz, r, datestr(now)};
	T = cell2table(C);
	T.Properties.VariableNames = {'CellNum', 'PRs', 'Sign', 'CellType', 'Ribbons', 'XYZ', 'Size', 'TimeStamp'};
end % makeRow
end % methods
end % classdef 