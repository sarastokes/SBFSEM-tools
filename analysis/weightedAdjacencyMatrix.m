function adjMat = weightedAdjacencyMatrix(contacts, weight)
	% make adjacency matrix with contact strengths
	% INPUTS:
	% 	contacts 					vector of a-b pairs
	%		weight 						weight vector if not with contacts
	% OUTPUTS:
	%		adjMat 						matrix
	%
	% 6Jul2017 - SSP - created

	adjMat = zeros(max(max(contacts)));

	if nargin < 2 && size(contacts,2) == 3
		weight = contacts(:, 3);
	end

	for ii = 1:size(contacts)
		adjMat(contacts(ii,1), contacts(ii,2)) = weight(ii);
	end