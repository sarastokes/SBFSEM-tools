function rgb = lighten(rgb, fac)
	% LIGHTEN
	% 
	% Syntax:
	%	rgb = light(rgb, fac);
	%
	% Inputs:
	%	rgb 	Color vector
	%	fac 	Factor to lighten by (0-1, default = 0.5)
	%
	% Outputs
	%	rgb 	Color vector
	%
	% History:
	%	15Oct2018 - SSP - pulled from graphDataOnline

	if nargin < 2
		fac = 0.5;
	end
	
	rgb = rgb + (fac * (1-rgb));
end