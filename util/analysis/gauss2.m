function g = gauss2(mu, sig)
	% symmetric 2d gaussian filter
	%
	% 10Aug2017 - SSP - created

	g = exp(-x.^2 / (2*sig^2)); 
	g = g' * g;
	g = g/sum(g(:));