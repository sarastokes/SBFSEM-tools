function str = getVikingURL(cellNum, source, numHops)
    % format into URL for Viking and copy to clipboard
    % INPUTS:
    %   cellNum         cell number to export
    %   source          tissue block
    %   numHops         network degrees, leave empty for morphology
    % OUTPUT:
    %   str             URL to get .tlp from Viking server
    
    if nargin < 3
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
            str = [str, sprintf('%s/export/morphology/tlp?id=%u', source, cellNum)];
        case 'network'
            str = [str, sprintf('%s/export/network/tlp?id=%u&hops=%u',...
                source, cellNum, numHops)];
    end
    
    % copy to clipboard
    clipboard('copy', str);
    