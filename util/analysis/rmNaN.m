function [data, ind] = rmNaN(data, dim)
	% remove all rows containing NaNs
	% 	INPUTS: 
	%		data	matrix 
	%
	% 12Aug2017 - SSP - created

	if nargin < 2
		dim = 2;
    end
    
    ind = any(isnan(data), dim);
	data(any(isnan(data), dim), :) = [];