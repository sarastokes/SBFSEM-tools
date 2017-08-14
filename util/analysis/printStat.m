function str = printStat(vec, showN)
	% PRINTSTAT  Print the mean and SEM to cmd line
	%
	% INPUTS:
	%	vec 		vector of data
	%	showN		include N (default = false)
	%
	% 12Aug2017 - SSP - created

	if nargin < 2
		showN = false;
	end

	str = sprintf('%.3f +- %.3f', mean(vec), sem(vec));
	if showN
		str = [str, sprintf(' (n=%u)', numel(vec))];
	end
	fprintf([str '\n']);