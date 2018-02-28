function [linkedIDs, G] = getStructureLinks(neuron, synapseType)
	% GETSTRUCTURELINKS
	%
	% Description:
	%	Returns the IDs all cells linked to input neuron.
	%
	% Syntax:
	%	[linkedIDs, G] = getStructureLinks(neuron, synapseType);
	%
	% Inputs:
	%	neuron  		Neuron object
	% Optional input:
	%	synapseType 	Synapse name (char or StructureType)
	%
	% Outputs:
	%	linkedIDs 		Structure IDs of linked cells (vector)
	%	G 				Network of connected neurons (digraph)
	%
	% See also:
	%	READODATA, NEURON, GRAPH
	%
	% History:
	%	26Feb2018 - SSP
	% ------------------------------------------------------------------
	assert(isa(neuron, 'Neuron'), 'Input neuron object');
	
	url = [getServiceRoot('i'), 'StructureLinks?$filter='];

	postTemplate = 'TargetID eq %u &$expand=Source($expand=Parent($select=ID))';
	preTemplate = 'SourceID eq %u &$expand=Target($expand=Parent($select=ID))';
	bothTemplate = ['SourceID eq %u or TargetID eq %u',...
		'&$expand=Source($expand=Parent($select=ID)),',...
		'Target($expand=Parent($select=ID))'];
	parseBoth = true;
	
	if nargin < 2
		IDs = neuron.synapses.ID;
		url = [url, bothTemplate];
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
			url = [url, bothTemplate];
		end
    end

    linkedIDs = [];
    
	for i = 1:numel(IDs)
        if parseBoth
            importedData = readOData(sprintf(url), IDs(i), IDs(i));
        else
            importedData = readOData(sprintf(url, IDs(i)));
        end
        data = importedData.value;

		linkedIDs = [linkedIDs, parsePre(data), parsePost(data)]; %#ok
    end
    
    if nargout == 2 && ~isempty(linkedIDs)
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
		ID = data.Target.Parent.ID;
	else
		ID = [];
	end
end

function ID = parsePost(data)
	% PARSEPOST  Get IDs of post-synaptic neurons
	if isfield(data, 'Source')
		ID = data.Source.Parent.ID;
	else
		ID = [];
	end
end