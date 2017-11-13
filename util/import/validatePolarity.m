function value = validatePolarity(guess)
	% VALIDATEPOLARITY 
	%
	% 30Sept2017 - SSP

	value = [0 0];
	if ~isempty(guess)
		if isvector(guess) && numel(guess) == 2
			value = guess;
		elseif ischar(guess)
			switch lower(guess)
				case 'on'
					value = [1 0];
				case 'off'
					value = [0 1];
				otherwise
					value = [1 1];
			end
		end
	end
