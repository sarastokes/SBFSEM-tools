function value = validateSubType(guess, cellType)
	% VALIDATESUBTYPES
	% 
	% 30Sept2017 - SSP

	if ~isempty(cellType) && ~isempty(guess)
		x = getCellSubtypes(cellType);
		if any(ismember(x, lower(guess)))
			ind = find(not(cellfun('isempty',...
				strfind(x, lower(guess)))));
			value = [x{ind}];
		else
			fprintf('subtype %s not found\n', guess);
			value = [];
		end
	else
		value = [];
	end