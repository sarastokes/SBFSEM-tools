function T = getSynapses(neuron, localname)
    % GETSYNAPSES  Return rows for unique synapses of a specific type
    
    row = strcmp(neuron.dataTable.LocalName, localname) & neuron.dataTable.Unique == 1;
    T = neuron.dataTable(row,:);
    