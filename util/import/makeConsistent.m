function makeConsistent(neuron)
	% MAKECONSISTENT  Old conventions trigger warnings

	assert(isa(neuron, 'NeuronAPI'), 'Input neuron object');

	if ~isempty(intersect(neuron.synapses.TypeID, [181, 182, 240, 241]))
		warning('Found old GABA synapse marker');
	end