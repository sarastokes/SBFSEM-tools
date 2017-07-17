function adjMat = weightedAdjacencyMatrix(contacts, weight)
	% make adjacency matrix with contact strengths
	% INPUTS:
	% 	contacts 					vector of a-b pairs
	%		weight 						weight vector if not with contacts
	% OUTPUTS:
	%		adjMat 						matrix
	%
	% 6Jul2017 - SSP - created

	entries = max(size(contacts));

	adjMat = zeros(entries, entries);

	if nargin < 2
		if size(contacts,2) == 3
			weight = contacts(:, 3);
		else
			error('use adjacencyMatrix.m');
			return;
		end
	end

	for ii = 1:entries
		adjMat(contacts(ii,1), contacts(ii,2)) = weight(ii);
	end