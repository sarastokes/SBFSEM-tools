function str = getVolumeAbbrev(source)

    switch source
        case 'NeitzInferiorMonkey'
            str = 'i';
        case 'NeitzNasalMonkey'
            str = 'n';
        case 'NeitzTemporalMonkey'
            str = 't';
        case 'RC1'
            str= 'r';
        otherwise
            error('SBFSEM:IncorrectInput', 'Volume abbreviation not found');
    end