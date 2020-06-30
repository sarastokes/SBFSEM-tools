function varargout = printStat(vec, useSD, showN)
	% PRINTSTAT  
    %
    % Description:
    %   Print basic stats to cmd line in format: MEAN +- SEM (N)
	%
	% Input:
	%	vec 		Data (vector, or matrix with rows = separate data)
    % Optional input:
	%	useSD		Use SD instead of SEM (default = false)
    %   showN       Include the number of samples (default = true)
    %
    % Output:
    %   stats       Char printed to the cmd line
	%
    % History:
	%   12Aug2017 - SSP - created
    %   18Jan2018 - SSP - changed default N, output options
    %   27May2020 - SSP - changed to accept columnated data
    % ---------------------------------------------------------------------

    if nargin < 2 || isempty(useSD)
        useSD = false;
    end
    
    if nargin < 3
        showN = true;
    end
    
    if size(vec, 1) == 1
        vec = vec';
    end
    
    template = '%.3f +- %.3f';    
    
    for i = 1:size(vec, 2)
        if useSD
            str = sprintf(template, mean(vec(:, i)), std(vec(:, i)));
        else
            str = sprintf(template, mean(vec(:, i)), sem(vec(:, i)));
        end

        if showN
            fprintf([str, sprintf(' (n=%u)', numel(vec(:, i))), '\n']);
        else
            fprintf([str, '\n']);
        end
    end
    
    if nargout > 0
        varargout(1) = {str};
    end