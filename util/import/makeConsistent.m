function makeConsistent(neuron)
	% MAKECONSISTENT  Old conventions trigger warnings

	assert(isa(neuron, 'sbfsem.Neuron'), 'Input neuron object');

	if ~isempty(intersect(neuron.synapses.TypeID, [181, 182, 240, 241]))
		warning('Found old GABA synapse marker');
	end