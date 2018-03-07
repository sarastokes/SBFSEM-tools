function reverseLight(axHandle)
	% REVERSELIGHT

	if nargin == 0
		axHandle = gca;
	else
		assert(ishandle(axHandle), 'Input axes handle');
	end

	view(axHandle, 0, -90);
	delete(findall(axHandle, 'Type', 'light'));
	lightangle(axHandle, 45, -30);
	lightangle(axHandle, 225, -30);
