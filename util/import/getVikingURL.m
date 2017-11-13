function str = getVikingURL(cellNum, source, varargin)
    % format into URL for Viking and copy to clipboard
    % INPUTS:
    %   cellNum         cell number to export
    %   source          tissue block
    % OPTIONAL:
    %   fileType        ['tlp']   file type: tlp, dot, graphml, json
    %   numHops         []   network degrees, leave empty for morphology
    % OUTPUT:
    %   str             URL to get file from Viking server
    
    ip = inputParser();
    addRequired(ip, 'cellNum', @isnumeric);
    addRequired(ip, 'source', @(x) any(validatestring(lower(x),...
        {'inferior', 'temporal', 'rc1', 'i', 't', 'r'})));
    addParameter(ip, 'numHops', [], @isnumeric);
    addParameter(ip, 'fileType', 'tlp', @(x) any(validatestring(lower(x),... 
        {'tlp', 'dot', 'graphml', 'json', 'dae'})));
    parse(ip, cellNum, source, varargin{:});
    
    cellNum = ip.Results.cellNum;
    source = ip.Results.source;
    fileType = ip.Results.fileType;
    numHops = ip.Results.numHops;
       
    if isempty(numHops)
        report = 'morphology';
    else
        report = 'network';
    end
    
    switch source
        case {'temporal', 't', 'neitztemporal', 'neitztemporalmonkey'}
            source = 'NeitzTemporalMonkey';
        case {'inferior', 'i', 'neitzinferior', 'neitzinferiormonkey'}
            source = 'NeitzInferiorMonkey';
        case {'rc1', 'marcrc1'}
            source = 'RC1';
        otherwise
            error('source not found!');
    end
    
    str = 'http://websvc1.connectomes.utah.edu/';
    
    switch report
        case 'morphology'
            str = [str, sprintf('%s/export/morphology/%s?id=%u',... 
                source, fileType, cellNum)];
        case 'network'
            str = [str, sprintf('%s/export/network/%s?id=%u&hops=%u',...
                source, fileType, cellNum, numHops)];
    end
    
    % copy to clipboard
    clipboard('copy', str);
    