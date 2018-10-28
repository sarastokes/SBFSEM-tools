function IDs = printOffEdges(neuron)
    IDs = neuron.offEdges;
    
    IDs(ismember(IDs, neuron.terminals)) = [];
    
