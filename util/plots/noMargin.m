function noMargin(axHandle)
	% NOMARGIN
	%
	% Description:
	%	Expand the axes to fill figure window
	%
	% Syntax:
	%	noMargin(axHandle);
	% 
	% Input:
	%	axHandle 		axes handle (default = gca)
	%
	% History:
	%	3Mar2018 - SSP
	% ------------------------------------------------------------------

	if nargin == 0
		axHandle = gca;
	end

	p = get(axHandle, 'TightInset');
	set(axHandle, 'Position', [p(1), p(2), 1-p(3)-p(1), 1-p(4)-p(2)]);
end