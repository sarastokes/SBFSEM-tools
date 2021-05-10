function [h1, h2] = showLinkedSynapses(neuron, synapseName, varargin)
    % SHOWLINKEDSYNAPSES
    %
    % Description:
    %   Shows location of synapses colored by whether they are linked
    %
    % Syntax:
    %   [h1, h2] = showLinkedSynapses(neuron, synapseName, varargin)
    %
    % Inputs:
    %   neuron          sbfsem.core.NeuronAPI object
    %   synapseName     Synapse name
    %   Additional key/value inputs go to sbfsem.util.plot3
    %
    % Outputs:
    %   h1              Handle to linked neuron markers
    %   h2              Handle to unlinked neuron markers
    %
    % See also:
    %   SYNAPSESPHERE, GETLINKEDNEURONS, PLOTLINKEDNEURONS
    %
    % History:
    %   6Aug2019 - SSP
    %   14Jan2020 - SSP - Compatibility w/ link property, switched to plot3
    %   19Feb2020 - SSP - Added error checking and improved documentation
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'),...
        'Must import a neuron object');
    neuron.checkLinks();

    T = neuron.links(strcmp(neuron.links.SynapseType, synapseName), :);
    if isempty(T)
        error('c%u has no synapses of type: %s', neuron.ID, synapseName);
    end

    ax = golgi(neuron);
    h1 = sbfsem.util.plot3(T{~isnan(T.NeuronID), 'SynapseXYZ'}, ...
        'ax', ax, 'Color', rgb('mint'),...
        'Tag', 'LinkedSynapse', varargin{:});
    h2 = sbfsem.util.plot3(T{isnan(T.NeuronID), 'SynapseXYZ'}, ...
        'ax', ax, 'Color', rgb('salmon'),... 
        'Tag', 'UnlinkedSynapse', varargin{:});
    axis(ax, 'tight');
    tightfig(gcf);
    
    fprintf('\tc%u - %u of %u %s are linked\n', neuron.ID,... 
        nnz(~isnan(T.NeuronID)), numel(T.NeuronID), synapseName);
