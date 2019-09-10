function [ax, T] = showLinkedSynapses(neuron, synapseType, varargin)
    % SHOWLINKEDSYNAPSES
    %
    % Syntax:
    %   [ax, T] = showLinkedSynapses(neuron, synapseType, varargin)
    %
    % Inputs:
    %   neuron          sbfsem.core.NeuronAPI object
    %   synapseType     Synapse name
    %   Additional key/value inputs go to synapseSphere
    % Outputs:
    %   ax              Axis handle
    %   T               table of linked IDs and synapse IDs
    %
    % See also:
    %   SYNAPSESPHERE, GETLINKEDNEURONS
    %
    % History:
    %   6Aug2019 - SSP
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'),...
        'Must import a neuron object');

    ax = golgi(neuron);
    [linkedIDs, synapseIDs] = getLinkedNeurons(neuron, synapseType);

    hasLinkedID = ~isnan(linkedIDs);
    synapseSphere(neuron, synapseIDs(hasLinkedID),...
        'ax', ax, 'FaceColor', rgb('emerald'),...
        'Tag', 'LinkedSynapse', varargin{:});
    synapseSphere(neuron, synapseIDs(~hasLinkedID),...
        'ax', ax, 'Tag', 'UnlinkedSynapse', varargin{:});
    
    if nargout == 2
        T = table(linkedIDs, synapseIDs);
    end

