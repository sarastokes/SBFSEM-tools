function source = validateSource(source)
    % VALIDATESOURCE  Match string to volume names
   switch lower(source)
        case {'temporal', 't', 'neitztemporal', 'neitztemporalmonkey'}
            source = 'NeitzTemporalMonkey';
        case {'inferior', 'i', 'neitzinferior', 'neitzinferiormonkey'}
            source = 'NeitzInferiorMonkey';
        case {'rc1', 'marcrc1', 'r'}
            source = 'RC1';
        otherwise
            error('source not found!');
    end