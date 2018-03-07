function value =  validateNeuronAttributes(key, guess)
	% VALIDATENEURONATTRIBUTES
	%
	% Not currently used. A collection of old validation functions

	switch key
	case 'celltype'
        if ~isempty(guess)
            x = getCellTypes;
            ind = find(not(cellfun('isempty',...
                strfind(getCellTypes(1), upper(guess))))); %#ok<STRCL1>
            value = [x{ind}]; %#ok<FNDSB>
        else
        	value = [];
        end
	case 'polarity'
		value = [0 0];
		if ~isempty(guess)
			if isvector(guess) && numel(guess) == 2
				value = guess;
			elseif ischar(guess)
				switch lower(guess)
				case 'on'
					value(1) = 1;
				case 'off'
					value(2) = 1;
				otherwise
					value = [1 1];
				end
			end
		end
	case {'coneinputs', 'inputs', 'prs'}
		value = zeros(1,3);
		if ~isempty(guess)
			switch numel(guess)
				case 1
					value(guess) = 1;
				case 3
					value = guess;
			end
		end
	case 'strata'
		value = zeros(1,5);
		if ~isempty(guess)
			if numel(guess) == 5 && max(guess) == 1
				value = guess;
			elseif max(guess) <= 5
				value(guess) = 1;
			end
		end
	otherwise
		warning('Incorrect key, empty value returned');
		value = [];
	end

