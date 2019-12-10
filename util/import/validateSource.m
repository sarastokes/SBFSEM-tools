function source = validateSource(source)
    % VALIDATESOURCE  Match string to volume names
    %
    % Syntax:
    %   source = validateSource(source)
    %
    % Input:
    %   source      Volume name or abbreviation (char)
    % Output:
    %   source      Official volume name
    %
    % See also:
    %   SBFSEM.BUILTIN.VOLUMES
    %
    % History:
    %   9Dec2019 - SSP - Added Nasal volume
    % ---------------------------------------------------------------------
    
   switch lower(source)
        case {'temporal', 't', 'neitztemporal', 'neitztemporalmonkey', 'temp'}
            source = 'NeitzTemporalMonkey';
        case {'inferior', 'i', 'neitzinferior', 'neitzinferiormonkey', 'inf'}
            source = 'NeitzInferiorMonkey';
        case {'nasal', 'n', 'neitznasal', 'neitznasalmonkey'}
            source = 'NeitzNasalMonkey';
        case {'rc1', 'marcrc1', 'r'}
            source = 'RC1';
        otherwise
            error('source not found!');
    end