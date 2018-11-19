function data = getLastModifiedAnnotation(ID, source)
    % GETLASTMODIFIEDANNOTATION
    %
    % Description:
    %   Returns data for structure's last modified annotation
    %
    % Syntax:
    %   data = getLastModifiedAnnotation(ID, source)
    %
    % Inputs:
    %   ID      Viking Structure ID #
    %   source  Volume name or abbreviation
    %
    % History:
    %   17Nov2018 - SSP
    % ---------------------------------------------------------------------
    
    if nargin < 3
        N = 1;
    end

    source = validateSource(source);
    
    url = [getServiceRoot(source), 'Locations?$filter=ParentID eq ',...
        num2str(ID), '&$orderby=LastModified desc&$top=1'];
    
    data = readOData(url);
    data = data.value{:};
end