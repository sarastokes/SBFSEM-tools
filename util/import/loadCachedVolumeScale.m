function volumeScale = loadCachedVolumeScale(source)
    % LOADCACHEDVOLUMESCALE
    %
    % Description:
    %   Load cached volume scale data.
    %
    % Syntax:
    %   volumeScale = loadCachedVolumeScale(source);
    % 
    % Inputs:
    %   source      Volume name or abbreviation
    %   
    % Notes
    %   Volume scale is static and doesn't need to be imported each time,
    %
    % History:
    %   25Nov2018 - SSP
    % ---------------------------------------------------------------------

    source = validateSource(source);
    
    switch source
        case 'NeitzInferiorMonkey'
            volumeScale = [7.5, 7.5, 90];
        case 'NeitzNasalMonkey'
            volumeScale = [5, 5, 50];
        case 'NeitzTemporalMonkey'
            volumeScale = [7.5, 7.5, 70];
        case {'MarcRC1', 'RC1'}
            volumeScale = [2.18 2.18 90];
    end