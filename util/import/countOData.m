function data = countOData(endpoint)
    % COUNTODATA  
    %
    % Description:
    %   Counts the number of entries returned from an OData query
    %
    % Syntax:
    %   data = countOData(endpoint);
    %
    % Input:
    %   endpoint        OData query URL
    %
    % Output:
    %   data            Number returned
    %
    % History:
    %   13Nov2017 - SSP
    %   6Mar2018 - SSP - Specified weboptions before webread call
    % ---------------------------------------------------------------------
    
    opt = weboptions('ContentType', 'text', 'Timeout', 60);
    data = webread(endpoint, opt);
    
    % Cut out the random characters and convert to double
    data = data(isstrprop(data, 'digit'));
    data = str2double(data);