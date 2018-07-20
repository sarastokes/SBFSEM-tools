function transform = validateTransform(transform, source)
    % VALIDATETRANSFORM
    %
    % Inputs:
    %   transform       sbfsem.core.Transforms
    %   source          volume name or abbreviation
    %
    % History:
    %   19Jul2018 - SSP
    % --------------------------------------------------------------------

    source = validateSource(source);
    if transform == sbfsem.core.Transforms.SBFSEMTools ...
            && ~strcmp(source, 'NeitzInferiorMonkey')
        transform = sbfsem.core.Transforms.None;
    end
