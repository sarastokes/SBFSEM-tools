function [G, T] = addToNetwork(G, neuron, synapseName, varargin)
	% ADDTONETWORK
    %
    % Description:
    %   Add a neuron and all neurons linked by a specific synapse type to a
    %   directed graph.
    %
    % Syntax:
    %   [G, T] = addToNetwork(G, neuron, synapseName, varargin);
    %
    % Inputs:
    %   G               digraph
    %   neuron          Neuron object
    %   synapseName     char or sbfsem.core.StructureTypes
    % Optional key/value inputs:
    %   C1              Colormap index for Neuron object (default = 0)
    %   C2              Colormap index for linked neurons (default = 1)
    %   useSoma         Logical (default = false)
    %
    % See also:
    %   PLOTNETWORK, GETLINKEDNEURONS, DIGRAPH
    %   
	% History:
	%   1Oct2018 - SSP
    % ---------------------------------------------------------------------

	ip = inputParser();
	ip.CaseSensitive = false;
	addParameter(ip, 'C1', 0, @isnumeric);
	addParameter(ip, 'C2', 1, @isnumeric);
	addParameter(ip, 'useSoma', false, @islogical);
	parse(ip, varargin{:});
    
    % Get soma location if needed
	useSoma = ip.Results.useSoma;
    if useSoma
        xyz = neuron.getSomaXYZ();
    end
    
    if ischar(synapseName)
        structureType = sbfsem.core.StructureTypes.fromStr(synapseName);
    elseif isa(synapseName, 'sbfsem.core.StructureTypes')
        structureType = synapseName;
        synapseName = char(structureType);
    end
    
    warning('off', 'MATLAB:table:RowsAddedExistingVars');

	if isempty(G.Nodes) || ~findnode(G, num2str(neuron.ID))
		G = G.addnode(num2str(neuron.ID));
		if ismember('NodeColors', G.Nodes.Properties.VariableNames)
			G.Nodes.NodeColors(end) = ip.Results.C1;
			if useSoma
				G.Nodes.X(end) = xyz(1);
				G.Nodes.Y(end) = xyz(2);
			end
		else
			G.Nodes.NodeColors = ip.Results.C1;
			if useSoma				
				G.Nodes.X = xyz(1);
				G.Nodes.Y = xyz(2);
			end
		end
	end
    
    [linkedIDs, synapseIDs] = getLinkedNeurons(neuron, synapseName);
    nodeIDs = unique(linkedIDs(~isnan(linkedIDs)));
    for i = 1:numel(nodeIDs)
        if ~findnode(G, num2str(nodeIDs(i)))
            G = G.addnode(num2str(nodeIDs(i)));
            G.Nodes.NodeColors(end) = ip.Results.C2;
            if useSoma
                newNeuron = Neuron(nodeIDs(i), neuron.source);
                xyz = newNeuron.getSomaXYZ();
                G.Nodes.X(end) = xyz(1);
                G.Nodes.Y(end) = xyz(2);
            end
        end
        synapseWeight = numel(find(linkedIDs == nodeIDs(i)));
        if structureType.isPre
            G = G.addedge(num2str(nodeIDs(i)), num2str(neuron.ID), synapseWeight);
        else
            G = G.addedge(num2str(neuron.ID), num2str(nodeIDs(i)), synapseWeight);
        end
    end
    
    % Create a table of linked cell and synapse IDs
    if nargout == 2
        T = table(linkedIDs, synapseIDs);
        T = sortrows(T, 'linkedIDs');
    end
    
    warning('on', 'MATLAB:table:RowsAddedExistingVars');