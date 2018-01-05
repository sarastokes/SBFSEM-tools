function updateTransform(S, source)
    % XYTRANSFORM
    %
    % Inputs:
    %   S       structure output from
    %   source  volume name
    
    source = validateSource(source);
    switch source
        case 'NeitzInferiorMonkey'
            data = dlmread('XY_OFFSET_NEITZINFERIORMONKEY.txt');
        otherwise
            disp('no transform available');
            return;
    end
    
    newSections = S.sections;
    xOffset = S.xMedian;
    yOffset = S.yMedian;
    
    data(newSections, 2) = data(newSections, 2) + xOffset;
    data(newSections, 3) = data(newSections, 3) + yOffset;
    
    % Send the changes up through the rest of the sections
    [sectionLimit, ind] = min(S.sections);
    
    data(1:sectionLimit, 2) = data(1:sectionLimit, 2) + xOffset(ind);
    data(1:sectionLimit, 3) = data(1:sectionLimit, 3) + yOffset(ind);
    
    dlmwrite('XY_OFFSET_NEITZINFERIORMONKEY.txt', data);
    
    
    
    