function volumeScale = getODataScale(source, verbose)
	% GETODATASCALE
    %
    % Description:
    %   Get volume scaling 
    %
    % Syntax:
    %   volumeScale = getODataScale(source, verbose);
    %
    % Input:
    %   source      Volume name or abbreviation
    % Optional input:
    %	verbose     True for full OData output (includes units)
    %
    % Output:
    %   volumeScale     XYZ dimension scaling (nm/pix, nm/pix, nm/section)
	%
    % History:
	%   1Oct2017 - SSP - Modified from VikingPlot
    %   3Nov2017 - SSP - Added concise output option
    %   5Mar2018 - SSP - New OData weboptions function
    % ---------------------------------------------------------------------
    
    if nargin < 2
        verbose = false;
    end

	endpoint = getODataURL([], source, 'scale');
    
	volumeScale = webread(endpoint, getODataOptions());
    
    if ~verbose
        volumeScale = [volumeScale.X.Value,... 
            volumeScale.Y.Value,...
            volumeScale.Z.Value];
    end
        