function animal = getAnimal(source)
    % GETANIMAL
    %
    % Description:
    %   Return animal name given volume name or abbreviation
    %
    % History:
    %   14May2018 - SSP
    % ---------------------------------------------------------------------
    
    source = validateSource(source);
    switch source
        case 'RC1'
            animal = 'rabbit';
        otherwise
            animal = 'monkey';
    end