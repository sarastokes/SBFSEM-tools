function value = validateConeInputs(guess)
	% VALIDATECONEINPUTS
	% 
	% 30Sept2017 - SSP

	value = zeros(1,3);
	if ~isempty(guess)
		switch numel(guess)
			case 1
				value(guess) = 1;
			case 3
				value = guess;
		end
	end