function neuron = CacheNeuron(ID, source)
	% CACHENEURON
	%
	% Description:
	%	Load or return neuron + synapses + 3D model from cache
	%
	% Inputs:
	%	ID				ID number
	%	source 			Volume name
	% ------------------------------------------------------------------

	assert(isnumeric(ID), 'ID must be numeric');
	source = validateSource(source);
	% Cached call to getNeuron
	neuron = cachedcall(@getNeuron, {{ID, source, true}});
    
    function neuron = getNeuron(input)
        neuron = Neuron(input);
        neuron.build();
    end
end