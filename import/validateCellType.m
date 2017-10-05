function value = validateCellType(guess)
	% VALIDATECELLTYPE
	%
	% 30Sept2017 - SSP

	if ~isempty(guess)
		x = getCellTypes();
		ind = find(not(cellfun('isempty',...
			strfind(getCellTypes(1), upper(guess)))));
		value = [x{ind}]; %#ok<FNDSB>
	else
		value = [];
	end