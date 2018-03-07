function [IE, numExc, numInh] = ieRatio(neuron, verbose)
	% IERATIO
	%
	% Description:
	%	A simple IE ratio calculation
	%
	% Syntax:
	%	[IE, numExc, numInh] = ieRatio(neuron);
	%
	% Input:
	%	neuron 			Neuron object
	% Optional input:
	%	verbose 		Print results to cmd line (default = false)
	%
	% Outputs:
	%	IE 				Ratio of inhibitory:excitatory synapses
	%	numExc 			Number of excitatory synapses
	%	numInh 			Number of inhibitory synapses
	%
	% Note:
	%	Defines inhibition as the number of conventional post-synapses
	%	and excitation as the number of ribbon post-synapses.
	%
	% History 
	%	5Mar2018 - SSP
	% ------------------------------------------------------------------

	assert(isa(neuron, 'Neuron'), 'Input a neuron object');
	if nargin < 2
		verbose = false;
    end
    neuron.checkSynapses();

	numExc = nnz(neuron.synapses.LocalName == 'RibbonPost');
	numInh = nnz(neuron.synapses.LocalName == 'ConvPost');
	if verbose
		fprintf('c%u has %u excitatory and %u inhibitory synapses\n',...
			neuron.ID, numExc, numInh);
	end

	IE = numInh/(numInh+numExc);
	if verbose
		fprintf('\tIE ratio is %.3g\n', IE);
	end