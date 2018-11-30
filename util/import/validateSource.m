function source = validateSource(source)
    % VALIDATESOURCE  Match string to volume names
    %
    % Syntax:
    %   source = validateSource(source)
    %
    % Input:
    %   source      Volume name or abbreviation (char)
    % ---------------------------------------------------------------------
    
   switch lower(source)
        case {'temporal', 't', 'neitztemporal', 'neitztemporalmonkey', 'temp'}
            source = 'NeitzTemporalMonkey';
        case {'inferior', 'i', 'neitzinferior', 'neitzinferiormonkey', 'inf'}
            source = 'NeitzInferiorMonkey';
        case {'rc1', 'marcrc1', 'r'}
            source = 'RC1';
        otherwise
            error('source not found!');
    end