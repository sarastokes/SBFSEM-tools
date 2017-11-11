function data = countOData(endpoint)
    % COUNTODATA  
    
    data = webread(endpoint,...
        'ContentType', 'text',...
        'Timeout', 30);
    
    % Cut out the random characters and convert to double
    data = data(isstrprop(data, 'digit'));
    data = str2double(data);