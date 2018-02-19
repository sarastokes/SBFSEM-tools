function IDs = getOpenEnded(neuron, varargin)
    % GETOPENENDED
    %
    % Description:
    %	Returns location IDs of likely unfinished branches
    %
    % Input:
    %	neuron              Neuron object
    % Optional key/value inputs:
    % 	SomaThreshold 		Cutoff distance from soma ([])
    %	OffEdge 			Include off edges (true)
    %	Terminal 			Include terminals (false)
    %
    % Output:
    %   IDs                 Viking location IDs (vector)
    %
    % Note:
    %   OffEdge and Terminal are tags in Viking (from right-clicking on
    %   an annotation). I use Terminal for a branch that is ending and
    %   OffEdge for a branch that I know continues but have yet to 
    %   annotate out.
    %
    % History:
    %	11Feb2018 - SSP
    % ---------------------------------------------------------------------

    ip = inputParser();
    ip.CaseSensitive = false;
    addParameter(ip, 'SomaThreshold', [], @isnumeric);
    addParameter(ip, 'OffEdge', true, @islogical);
    addParameter(ip, 'Terminal', false, @islogical);
    parse(ip, varargin{:});
    somaThreshold = ip.Results.SomaThreshold;
    includeOffedges = ip.Results.OffEdge;
    includeTerminal = ip.Results.Terminal;

    [G, nodeIDs] = graph(neuron);

    degOnes = nodeIDs(G.degree < 2,:);
    fprintf('Found %u nodes with degree 1\n', numel(degOnes));

    row = ismember(neuron.nodes.ID, degOnes);

    T = neuron.nodes(row, :);

    % Filter by offedge and terminal
    if ~includeOffedges
        T = T(~T.OffEdge,:);
    end
    if ~includeTerminal
        T = T(~T.Terminal,:);
    end

    % Get the distance from soma
    if ~isempty(somaThreshold)
        somaDistance = fastEuclid3d(neuron.getSomaXYZ, T.XYZum);
        fprintf('Found %u annotations within soma distance threshold\n',...
            nnz(somaDistance < somaThreshold));
        T(somaDistance > somaThreshold, :) = [];
    end

    IDs = T.ID;