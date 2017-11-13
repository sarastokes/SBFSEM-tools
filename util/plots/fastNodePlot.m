function fh = fastNodePlot(neuron, micronFlag)
    % FASTNODEPLOT  Gets the NeuronApp 3d plot w/out the app
    % INPUTS:
    %   neuron
    % OPTIONAL:
    %   micronFlag          [true] microns or viking pixels
    %   fh                  figureHandle
    %
    % 18Aug2017 - SSP - created
    
    fh = figure();
    ax = axes('Parent', fh,...
        'XColor', 'w', 'YColor', 'w');
        
    % Modified from populateGraphs method
    sc = getStructureColors();
    T = neuron.dataTable;
    
    skelRow = strcmp(T.LocalName, 'cell');
    if micronFlag
        xyz = table2array(T(skelRow, 'XYZum'));
    else
        xyz = table2array(T(skelRow, 'XYZ'));
    end
    skeleton = line('Parent', ax,...
        'XData', xyz(:,1), 'YData', xyz(:,2),...
        'Marker', '.', 'MarkerSize', 4, 'Color', [0.2 0.2 0.2],...
        'LineStyle', 'none');
    % throw out the cell body and multiple slide synapses
    rows = ~strcmp(T.LocalName, 'cell') & T.Unique == 1;
    % make a new table with only unique synapses
    synTable = T(rows, :);
    % group by LocalName
    [~, names] = findgroups(synTable.LocalName);
    % how many synapse types
    numSyn = numel(names);
    
    for ii = 1:numSyn
        xyz = getSynXYZ(T, names{ii}, micronFlag);
        line('Parent', ax,...
            'XData', xyz(:,1), 'YData', xyz(:,2), 'ZData', xyz(:,3),...
            'Color', sc(names{ii}), 'Marker', '.',...
            'MarkerSize', 10, 'LineStyle', 'none');
        str = cat(2, str, {sprintf('\color[rgb]{%.2f %.2f %.2f} %s',... 
            sc(names{ii}), names{ii}), char(10)});
    end
    % skip the last char10
    str{end} = [];
    
    annotation('textbox', dim, 'String', sprintf('%s\n', str{:}));
    