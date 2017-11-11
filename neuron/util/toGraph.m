function [G, h] = toGraph(ID, edgeData, plotFlag)
	% TOGRAPH  Create a graph

	if nargin < 3
		plotFlag = false;
	end

	if ischar(edgeData)
		[~, ~, edgeData, ~] = getNeuronOData(ID, edgeData);
	end

	edge_rows = edgeData.ID == ID;
	G = digraph(cellstr(num2str(edgeData.A(edge_rows,:))),...
		cellstr(num2str(edgeData.B(edge_rows,:))));

	if plotFlag
        figure();
		h = plot(G, 'Layout', 'force');
	end
