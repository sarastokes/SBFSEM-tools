classdef Mosaic < handle
	% essentially matlab's table class
	%
	% 29Jul2017 - SSP - created

properties
	dataTable
end

methods
	function obj = Mosaic(Neuron)
		T = obj.makeRow(Neuron);
		obj.dataTable = T;
	end % constructor

	function obj = add(obj, Neuron)
		% make sure Neuron isn't already in table
		if ~isempty(find(obj.dataTable.CellNum == Neuron.cellData.cellNum))
			selection = questdlg('Overwrite existing cell row?',...
				'Neuron overwrite dialog',...
				{'Yes', 'No', 'Yes'});
			if strcmp(selection, 'No')
				return;
			end
		end
		T = obj.makeRow(Neuron);
		obj.dataTable = [obj.dataTable; T];
	end % add

	function obj = rmRow(obj, rowNum)
		obj.dataTable(rowNum,:) = [];
	end % rmRow

	function obj = rmNeuron(obj, cellNum)
		row = obj.dataTable.CellNum == cellNum;
		if ~isempty(row)
			obj.dataTable(row,:) = [];
		else
			warndlg('cell %u not found in Mosaic', cellNum);
		end
	end % rmNeuron

	function obj = describe(obj, str)
		obj.dataTable.Properties.Description = str;
	end

	function display(obj)
		if ~isempty(obj.dataTable.Properties.Description)
			disp(obj.dataTable.Properties.Description);
		end
		disp(obj.dataTable);
	end % display

	function T = mosaic2table(obj)
		% ditch the mosaic class
		T = obj.dataTable;
	end % table
end % methods

methods (Static)
	function T = makeRow(Neuron)
		% find the row matching the somaNode uuid
		row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
		% get xyzr values
		xyz = table2array(Neuron.dataTable(row, 'XYZum'));
		r = Neuron.dataTable{row, 'Size'} / 2;

		if nnz(Neuron.cellData.onoff) == 2
			pol = 'onoff';
		elseif nnz(Neuron.cellData.onoff) == 0
			pol = '-';
		elseif Neuron.cellData.onoff(1) == 1
			pol = 'on';
		else
			pol = 'off';
		end
		coneInputs = Neuron.cellData.inputs; 
		switch nnz(coneInputs)
		case 0
			pr = '-';
		case 1
			if coneInputs(1) == 1
				pr = 'lm';
			elseif coneInputs(2) == 1
				pr = 's';
			elseif coneINputs(3) == 1
				pr = 'rod';
			end
		case 2
			pr = 'lms';
		case 3
			pr = 'all';
		end

		if ~isempty(Neuron.cellData.cellType)
			if isempty(Neuron.cellData.subType)
				n = Neuron.cellData.cellType;
			else
				n = [Neuron.cellData.subType, ' ', Neuron.cellData.cellType];
			end
		else
			n = '-';
		end

		ribbons = nnz(strcmp(Neuron.dataTable.LocalName, 'ribbon pre') & Neuron.dataTable.Unique);

		C = {Neuron.cellData.cellNum, pr, pol, n, ribbons, xyz, r};
		T = cell2table(C);
		T.Properties.VariableNames = {'CellNum', 'PRs', 'Sign', 'CellType', 'Ribbons', 'XYZ', 'Size'};
	end % makeRow
end % methods static
end % classdef