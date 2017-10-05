function value = validateStrata(guess)
	% VALIDATESTRATA
	%
	% 30Sept2017 - SSP

	value = zeros(1,5);
	if ~isempty(guess)
		if numel(guess) == 5 && max(guess) == 1
			value = guess;
		elseif max(guess) <= 5
			value(guess) = 1;
		end
	end