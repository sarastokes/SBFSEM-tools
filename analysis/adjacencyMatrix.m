function adjMat = adjacencyMatrix(contacts)
	% contacts between nodes (a - b)
	% INPUTS:
	% 	contacts 					vector of a-b pairs
	% OUTPUTS:
	%		adjMat 						for graph theory stuff
	%
	% 21Jun2017 - SSP - created

	adjMat = zeros(max(max(contacts)));

	for ii = 1:size(contacts)
		adjMat(contacts(ii,1), contacts(ii,2)) = 1;
	end