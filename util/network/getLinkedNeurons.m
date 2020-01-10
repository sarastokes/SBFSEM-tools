function [linkedIDs, synapseIDs, synapseXYZ] = getLinkedNeurons(neuron, synapseType, includeUnlinked)
% GETLINKEDNEURONS
%
% Description:
%	Returns the IDs of all cells linked to input neuron.
%
% Syntax:
%   % Return as separate variables
%	[linkedIDs, synapseIDs, synapseXYZ] = getLinkedNeurons(neuron, synapse);
%   % Return as a table (specify only a single output)
%   T = getLinkedNeurons(neuron, synapseType);
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
%   synapseXYZ          XYZ coordinates of each synapse
%
% Todo:
%   The colormap calculation required to plot the graph doesn't
%   handle networks with 2 or less nodes.
%
% See also:
%	READODATA, NEURON, GETSTRUCTURELINKS, GETALLLINKEDNEURONS
%
% History:
%	26Feb2018 - SSP
%   2Jun2018 - SSP - updated JSON decoding, added synapseID output
%   4Jun2018 - SSP - revised to new function, getLinkedNeurons
%   11Sept2018 - SSP - added argument to include/omit unlinked synapses
%   16Apr2019 - SSP - Added table option and synapse location output
%   6May2019 - SSP - Dealt with directionality in "undirected" synapses
%   10Jan2020 - SSP - More optimization for "undirected" synapses
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
        warning('No synapses of type %s were found\n', char(synapseType));
        linkedIDs = []; synapseXYZ = [];
        return;
    end

    if strcmp(char(synapseType), 'Unknown')
        % What a mess... see getUndirectedLinkedIDs info below
        [linkedIDs, finalSynapseIDs] = getUndirectedLinkedIDs(...
            getServiceRoot(neuron.source), synapseIDs);
    else
        url = [getServiceRoot(neuron.source), 'StructureLinks?$filter='];
        % Directed synapses use 'Source' for presynapses, 'Target' for postsynapses
        postTemplate = 'TargetID eq %u &$expand=Source($select=ParentID)';
        preTemplate = 'SourceID eq %u &$expand=Target($select=ParentID)';

        if synapseType.isPre()
            [linkedIDs, finalSynapseIDs] = getDirectedLinkedIDs(...
                [url, preTemplate], synapseType, synapseIDs);
        else
            [linkedIDs, finalSynapseIDs] = getDirectedLinkedIDs(...
                [url, postTemplate], synapseType, synapseIDs);
            if numel(linkedIDs) ~= numel(finalSynapseIDs)
                error('Number of linked IDs does not match synapse IDs!');
            end
        end
    end

    if ~includeUnlinked
        finalSynapseIDs = finalSynapseIDs(~isnan(linkedIDs));
        linkedIDs = linkedIDs(~isnan(linkedIDs));
    end
    
    % Use table to find only the unique rows
    T = unique(table(linkedIDs, finalSynapseIDs));
    T.Properties.VariableNames = {'NeuronID', 'SynapseID'};
    T = sortrows(T, 'NeuronID');
    % Get the synapse locations
    synapseXYZ = [];
    for i = 1:numel(T.SynapseID)
        synapseXYZ = cat(1, synapseXYZ, neuron.getSynapseXYZ(T.SynapseID(i)));
    end
    if nargout == 1
        T.SynapseXYZ = synapseXYZ;
        linkedIDs = T;
    elseif nargout > 1
        linkedIDs = T.NeuronID; synapseIDs = finalSynapseIDs;
    end
end

function [linkedIDs, finalSynapseIDs] = getDirectedLinkedIDs(url, synapseType, synapseIDs)
    % finalSynapseIDs duplicates synapseIDs with 2 post-synaptic neurons
    linkedIDs = []; finalSynapseIDs = [];
    for i = 1:numel(synapseIDs)
        importedData = readOData(sprintf(url, synapseIDs(i)));
        if numel(importedData.value) > 0
            for j = 1:numel(importedData.value)
                data = importedData.value{j};
                if synapseType.isPre()
                    newLinkedID = data.Target.ParentID;
                    if isempty(newLinkedID)
                        newLinkedID = NaN;
                    end
                    linkedIDs = cat(1, linkedIDs, newLinkedID);
                    finalSynapseIDs = cat(1, finalSynapseIDs, synapseIDs(i));
                else
                    newLinkedID = data.Source.ParentID;
                    if isempty(newLinkedID)
                        newLinkedID = NaN;
                    end
                    linkedIDs = cat(1, linkedIDs, newLinkedID);
                    finalSynapseIDs = cat(1, finalSynapseIDs, synapseIDs(i));
                end
            end
        else
            linkedIDs = cat(1, linkedIDs, NaN);
            finalSynapseIDs = cat(1, finalSynapseIDs, synapseIDs(i));
        end
        if numel(linkedIDs) ~= numel(finalSynapseIDs)
            error('Mismatch after %u', synapseIDs(i));
        end
    end
end

function [linkedIDs, finalSynapseIDs] = getUndirectedLinkedIDs(url, synapseIDs)
    % GETUNDIRECTEDLINKEDIDS
    % Undirected synapses like Unknown retain some directionality in
    % database, only there's no reliable way to know which direction the
    % synapse was formed in, so... query both.
    
    linkedIDs = []; finalSynapseIDs = [];  % for now
    urlOne = [url, 'Structures(%u)/SourceOfLinks/'];
    urlTwo = [url, 'Structures(%u)/TargetOfLinks/'];
    parentURL = [url, 'Structures(%u)?$select=ParentID'];
    
    for i = 1:numel(synapseIDs)
        try
            importedData = readOData(sprintf(urlOne, synapseIDs(i)));
            if isempty(importedData.value)
                importedData = readOData(sprintf(urlTwo, synapseIDs(i)));
                data = importedData.value{1};
                iLinkedID = data.SourceID;
            else
                data = importedData.value{1};
                iLinkedID = data.TargetID;
            end
            try
                data = readOData(sprintf(parentURL, iLinkedID));
                linkedIDs = cat(1, linkedIDs, data.ParentID);
            catch
                warning('No ParentID found for %u', iLinkedID);
                linkedIDs = cat(1, linkedIDs, NaN);
            end
        catch
            % Synapse is not linked to another structure
            linkedIDs = cat(1, linkedIDs, NaN);
        end
        finalSynapseIDs = cat(1, finalSynapseIDs, synapseIDs(i));
        
        if numel(linkedIDs) ~= numel(finalSynapseIDs)
            error('Mismatch after %u', synapseIDs(i));
        end
    end
end

