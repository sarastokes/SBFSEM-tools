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
    %   30Jan2020 - SSP - Added Marc lab volumes
    % ---------------------------------------------------------------------
    
    if isa(source, 'sbfsem.builtin.Volumes')
        source = char(source);
    elseif ischar(source)
        switch lower(source)
            case {'temporal', 't', 'neitztemporal', 'neitztemporalmonkey', 'temp'}
                source = 'NeitzTemporalMonkey';
            case {'inferior', 'i', 'neitzinferior', 'neitzinferiormonkey', 'inf'}
                source = 'NeitzInferiorMonkey';
            case {'nasal', 'n', 'neitznasal', 'neitznasalmonkey'}
                source = 'NeitzNasalMonkey';
            case {'rc1', 'marcrc1', 'r'}
                source = 'RC1';
            case {'rpc1', 'marcrpc1'}
                source = 'RPC1';
            case {'rc2', 'marcrc2'}
                source = 'RC2';
            case {'rpc2', 'marcrpc2'}
                source = 'RPC2';
            otherwise
                error('source not found!');
        end
    end