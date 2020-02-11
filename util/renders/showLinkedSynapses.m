function [h1, h2] = showLinkedSynapses(neuron, synapseName, varargin)
    % SHOWLINKEDSYNAPSES
    %
    % Syntax:
    %   [ax, T] = showLinkedSynapses(neuron, synapseName, varargin)
    %
    % Inputs:
    %   neuron          sbfsem.core.NeuronAPI object
    %   synapseName     Synapse name
    %   Additional key/value inputs go to sbfsem.util.plot3
    % Outputs:
    %   h1              Handle to linked neuron markers
    %   h2              Handle to unlinked neuron markers
    %
    % See also:
    %   SYNAPSESPHERE, GETLINKEDNEURONS, PLOT3, SBFSEM.UTIL.PLOT3
    %
    % History:
    %   6Aug2019 - SSP
    %   14Jan2020 - SSP - Compatibility w/ link property, switched to plot3
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'),...
        'Must import a neuron object');

    neuron.checkLinks();

    T = neuron.links(strcmp(neuron.links.SynapseType, synapseName), :);

    ax = golgi(neuron);

    h1 = sbfsem.util.plot3(T{~isnan(T.NeuronID), 'SynapseXYZ'}, ...
        'ax', ax, 'Color', rgb('mint'),...
        'Tag', 'LinkedSynapse', varargin{:});
    h2 = sbfsem.util.plot3(T{isnan(T.NeuronID), 'SynapseXYZ'}, ...
        'ax', ax, 'Color', rgb('salmon'),... 
        'Tag', 'UnlinkedSynapse', varargin{:});
    axis(ax, 'tight');
    tightfig(gcf);
    
    fprintf('%u of %u %s are linked\n',... 
        nnz(~isnan(T.NeuronID)), numel(T.NeuronID), synapseName);
