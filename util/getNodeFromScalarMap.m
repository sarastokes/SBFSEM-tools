function nodeID = getNodeFromScalarMap(value, map)
	% regretting using all these containers.Map..
	% INPUTS:
	%			value 			number(s) to match
	% 		map 				nodeData map
	% OUTPUT:
	%			nodeID 			keys corresponding to value
	%
	% 22Jun2017 - SSP - created

	x = map.values;
	if ~isscalar(x{1})
		error('only works with scalar maps');
	end

	x = cell2mat(x);
	nodeID = find(x == value);