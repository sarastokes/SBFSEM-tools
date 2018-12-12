function [linkedIDs, synapseIDs] = getLinkedNeurons(neuron, synapseType, includeUnlinked)
% GETLINKEDNEURONS
%
% Description:
%	Returns the IDs of all cells linked to input neuron.
%
% Syntax:
%	[linkedIDs, synapseIDs] = getLinkedNeurons(neuron, synapseType);
%
% Inputs:
%	neuron              Neuron object
%	synapseType         Synapse name (char or StructureType)
% Optional inputs:
%   includeUnlinked     Show unlinked synapse IDs (default = true) 
%
% Outputs:
%	linkedIDs           Structure IDs of linked cells (vector)
%   synapseIDs          Synapse IDs linked to above structure IDs (vector)
%
% Todo:
%   The colormap calculation required to plot the graph doesn't
%   handle networks with 2 or less nodes.
%
% See also:
%	READODATA, NEURON, GETSTRUCTURELINKS
%
% History:
%	26Feb2018 - SSP
%   2Jun2018 - SSP - updated JSON decoding, added synapseID output
%   4Jun2018 - SSP - revised to new function, getLinkedNeurons
%   11Sept2018 - SSP - added argument to include/omit unlinked synapses
% -------------------------------------------------------------------------

assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input neuron object');
if ischar(synapseType)
    synapseType = sbfsem.core.StructureTypes(synapseType);
end
if nargin < 3
    includeUnlinked = true;
else
    assert(islogical(includeUnlinked), 'IncludeUnlinked must be t/f');
end

% Find synapses
synapseIDs = neuron.synapseIDs(synapseType);
if isempty(synapseIDs)
    error('No synapses of type %s were found\n', char(synapseType));
end
% fprintf('Found %u IDs\n', numel(synapseIDs));


% OData query URL templates
url = [getServiceRoot(neuron.source), 'StructureLinks?$filter='];
% Directed synapses use 'Source' for presynapses, 'Target' for postsynapses
postTemplate = 'TargetID eq %u &$expand=Source($select=ParentID)';
preTemplate = 'SourceID eq %u &$expand=Target($select=ParentID)';

if synapseType.isPre()
    url = [url, preTemplate];
elseif synapseType.isPost()
    url = [url, postTemplate];
else
    url = [url, postTemplate];
end

% A list of pre/post-synaptic neurons
linkedIDs = [];

% Query OData for ParentID of linked synapses
for i = 1:numel(synapseIDs)
    importedData = readOData(sprintf(url, synapseIDs(i)));
    try
        data = importedData.value{1};
        if synapseType.isPre()
            linkedIDs = cat(1, linkedIDs, data.Target.ParentID);
        else
            linkedIDs = cat(1, linkedIDs, data.Source.ParentID);
        end
    catch
        linkedIDs = cat(1, linkedIDs, NaN);
    end
end

if ~includeUnlinked
    synapseIDs = synapseIDs(~isnan(linkedIDs));
    linkedIDs = linkedIDs(~isnan(linkedIDs));
end
