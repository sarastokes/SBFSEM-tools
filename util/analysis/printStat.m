function varargout = printStat(vec, showN)
	% PRINTSTAT  
    %
    % Description:
    %   Print basic stats to cmd line in format: MEAN +- SEM (N)
	%
	% Input:
	%	vec 		Data (vector)
    % Optional input:
	%	showN		Include N (default = true)
    %
    % Output:
    %   stats       Char printed to the cmd line
	%
    % History:
	%   12Aug2017 - SSP - created
    %   18Jan2018 - SSP - changed default N, output options
    % ---------------------------------------------------------------------

	if nargin < 2
		showN = true;
	end

	str = sprintf('%.3f +- %.3f', mean(vec), sem(vec));
	if showN
		str = [str, sprintf(' (n=%u)', numel(vec))];
	end
	fprintf([str '\n']);
    
    if nargout > 0
        varargout(1) = {str};
    end