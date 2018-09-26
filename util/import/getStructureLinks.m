function [linkedIDs, synapseIDs, G] = getStructureLinks(neuron, synapseType)
% GETSTRUCTURELINKS
% 
% Warning:
%   Deprecated! Remains with repository for backwards compatibility only.
%   Instead use GETLINKEDNEURONS
%
% Description:
%	Returns the IDs of all cells linked to input neuron.
%
% Syntax:
%	[linkedIDs, synapseIDs, G] = getStructureLinks(neuron, synapseType);
%
% Inputs:
%	neuron  		Neuron object
%	synapseType 	Synapse name (char or StructureType)
%
% Outputs:
%	linkedIDs 		Structure IDs of linked cells (vector)
%   synapseIDs      Synapse IDs linked to above structure IDs (vector)
%	G 				Network of connected neurons (digraph)
%
% Todo:
%   The colormap calculation required to plot the graph doesn't
%   handle networks with 2 or less nodes.
%
% See also:
%	READODATA, NEURON, GRAPH, GETLINKEDNEURONS
%
% History:
%	26Feb2018 - SSP
%   2Jun2018 - SSP - updated JSON decoding, added synapseID output
% -------------------------------------------------------------------------
assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input neuron object');

url = [getServiceRoot(neuron.source), 'StructureLinks?$filter='];

postTemplate = 'TargetID eq %u &$expand=Source($expand=Parent($select=ID))';
preTemplate = 'SourceID eq %u &$expand=Target($expand=Parent($select=ID))';
bothTemplate = ['SourceID eq %u or TargetID eq %u',...
    '&$expand=Source($expand=Parent($select=ID)),',...
    'Target($expand=Parent($select=ID))'];


if nargin < 2
    error('All synapses not yet implemented')
    % IDs = neuron.synapses.ID;
    % url = [url, bothTemplate];
else % Synapse-specific network
    if ischar(synapseType)
        synapseType = sbfsem.core.StructureTypes(synapseType);
    end
    
    IDs = neuron.synapseIDs(synapseType);
    
    if isPre(synapseType)
        url = [url, preTemplate];
        parseBoth = false;
    elseif isPost(synapseType)
        url = [url, postTemplate];
        parseBoth = false;
    else
        error('Bidirectional synapses are not yet implemented');
        % url = [url, bothTemplate];
        % parseBoth = true;
    end
end

linkedIDs = [];

fprintf('Found %u IDs\n', numel(IDs));

for i = 1:numel(IDs)
    if parseBoth
        importedData = readOData(sprintf(url), IDs(i), IDs(i));
    else
        importedData = readOData(sprintf(url, IDs(i)));
    end
    data = importedData.value{1};
    
    if ~isempty(parsePre(data))
        linkedIDs = [linkedIDs, parsePre(data)];
    elseif ~isempty(parsePost(data))
        linkedIDs = [linkedIDs, parsePost(data)];
    end
end
linkedIDs = linkedIDs';

if nargout == 2
    synapseIDs = IDs;
end

if nargout == 3 && ~isempty(linkedIDs)
    [a, b] = findgroups(linkedIDs);
    weights = splitapply(@numel, linkedIDs, a);
    names = arrayfun(@num2str, [b, neuron.ID], 'UniformOutput', false);
    G = digraph(numel(b)+1+zeros(size(b)), 1:numel(b), weights, names);
    figure();
    p = plot(G);
    p.LineWidth = 3;
    
    co = pmkmp(max(weights), 'cubicl');
    for i = 1:numel(b)
        highlight(p, [4 i], 'EdgeColor', co(weights(i), :));
    end
else
    G = [];
end
end


function ID = parsePre(data)
% PARSEPRE  Get ID of pre-synaptic neurons
if isfield(data, 'Target')
    ID = data.Target.ParentID;
else
    ID = [];
end
end

function ID = parsePost(data)
% PARSEPOST  Get IDs of post-synaptic neurons
if isfield(data, 'Source')
    ID = data.Source.ParentID;
else
    ID = [];
end
end

