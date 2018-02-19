function locIDs = findBSTExceptions(ID, edgeData, plotFlag)
	% FINDBSTEXCEPTIONS 
	% Locations that will not conform to binary search tree

	if nargin < 3
		plotFlag = false;
	end

	edgeData(edgeData.ID ~= ID,:) = [];
	[groups, groupNames] = findgroups(edgeData.A);
	x = splitapply(@numel, edgeData.A, groups);
	locIDs = groupNames(x > 2);
    fprintf('found %u BST-incompliant locations\n', numel(locIDs));

	if plotFlag
		[G,h] = toGraph(ID, edgeData, true);
		highlight(h, find(ismember(G.Nodes.Name, cellstr(num2str(locIDs)))),...
            'NodeColor', 'r');
	end
