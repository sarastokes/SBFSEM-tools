function stats = createStatsStructure(data, verbose)
    % CREATESTATSSTRUCTURE
    %
    % Description:
    %   Run statistics on data and return results as a structure
    %
    % Syntax:
    %   stats = createStatsStructure(data, verbose)
    %
    % Inputs:
    %   data        Data to run statistics with
    % Optional inputs:
    %   verbose     Print results to cmd line (default = true)
    %
    % Output: 
    %   stats       Structure containing common statistics
    %
    % See also:
    %   PRINTSTAT
    %
    % History:
    %   13Feb2020 - SSP
    % ---------------------------------------------------------------------

    if nargin < 2
        verbose = true;
    end

    % Columate
    data = data(:);

    if verbose
        disp('Mean +- SEM microns (n):')
        printStat(data);
    end

    stats = struct();
	stats.median = median(data);
	stats.sem = sbfsem.util.sem(data);
    stats.stdev = std(data);
    stats.var = var(data);  
    stats.avg = mean(data);
	stats.n = numel(data);  

    if verbose
        fprintf('SD = %.3g, var = %.3g\n', stats.stdev, stats.var);
        fprintf('Median IPL Depth = %.3g\n', stats.median);
    end
