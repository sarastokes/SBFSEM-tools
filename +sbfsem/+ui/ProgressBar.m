function ProgressBar(n, varargin)
    % PROGRESSBAR
    %
    % Description:
    %   Wrapper for progressbar from file exchange. Purpose is to avoid 
    %   unnecessary flashing of progressbar and only open when needed.
    %
    % Syntax:
    %   sbfsem.ui.ProgressBar(n, varargin)
    %
    % Inputs:
    %   n           Total number of iterations to be performed
    %   See lib/progressbar for the remaining inputs.
    %
    % See also:
    %   PROGRESSBAR
    %
    % History:
    %   21Sep2019 - SSP
    % --------------------------------------------------------------------

    if n >= 50
        progressbar(varargin{:});
    end