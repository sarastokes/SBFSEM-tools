function volumeScale = getODataScale(source, verbose)
	% GETODATASCALE  Get volume scaling 
    %   Inputs:
    %       source      volume name or abbreviation
    %       verbose     true for full odata output
	%
	% 1Oct2017 - SSP - modified from VikingPlot
    % 3Nov2017 - SSP - added concise output option
    
    if nargin < 2
        verbose = false;
    end

	endpoint = getODataURL([], source, 'scale');
    
	volumeScale = webread(endpoint,... 
		'Timeout', 30,...
		'ContentType', 'json');
    
    if ~verbose
        volumeScale = [volumeScale.X.Value,... 
            volumeScale.Y.Value,...
            volumeScale.Z.Value];
    end
        