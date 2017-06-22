function s = parseConnectivity(connectivityFile)
	% parse connectivity json file
	%
	% 21Jun2017 - SSP - created

	if ischar(connectivityFile) && strcmp(connectivityFile(end-3:end), 'json')
		fprintf('parsing with loadjson.m...');
		hops = loadjson(connectivityFile);
		fprintf('parsed\n');
	elseif isstruct(connectivityFile) % output from loadjson
		hops = connectivityFile;
	else
		error('input file name as string or struct from loadjson()');
	end

	s.fileName = hops.graph.attributes.file{2};
	s.parseDate = datestr(now);
	s.tulipData.numEdges = hops.graph.edgesNumber;
	s.tulipData.numNodes = hops.graph.nodesNumber;
	s.contacts = hops.graph.edges + 1;

	% get all the edge fieldnames
	s.edgeList = fieldnames(hops.graph.properties.LinkedStructures.edgesValues);
	% get the node names
	s.nodeList = fieldnames(hops.graph.properties.ID.nodesValues);

	% edges
	s.props.evalMap = containers.Map;
	s.props.etypeMap = containers.Map;
	s.props.elabelMap = containers.Map;
	s.props.enameMap = containers.Map;
	s.props.sourceMap = containers.Map;
	s.props.dirMap = containers.Map;
	s.props.loopMap = containers.Map;
	s.props.targetMap = containers.Map;
	% nodes
	s.props.nlabelMap = containers.Map;
	s.props.nnameMap = containers.Map;
	s.props.idMap = containers.Map;


	for ii = 1:length(s.nodeList)
		nodeName = s.nodeList{ii};
		s.props.nnameMap(nodeName) = nodeName;
		s.props.idMap(nodeName) = num2str(hops.graph.properties.ID.nodesValues.(nodeName));
		s.props.nlabelMap(nodeName) = hops.graph.properties.viewLabel.nodesValues.(nodeName);
	end % nodeList loop

	for ii = 1:length(s.edgeList)
		edgeName = char(s.edgeList{ii});
		s.props.enameMap(edgeName) = edgeName;

		tmp = hops.graph.properties.LinkedStructures.edgesValues.(edgeName);
		tmp = regexp(tmp, '   ', 'split');
		if isempty(tmp{1})
			numVal = 2:length(tmp);
		else
			numVal = 1:length(tmp);
		end
		edgeVal = zeros(length(numVal),2);

		for ii = 1:length(numVal)
			tmp{numVal(ii)}(regexp(tmp{numVal(ii)}, ' ')) = [];
			x = regexp(tmp{numVal(ii)}, ' ', 'split');
			x = cellfun(@str2double, x);
			edgeVal(ii,:) = x;
		end
		s.props.evalMap(edgeName) = edgeVal;

		s.props.etypeMap(edgeName) = hops.graph.properties.edgeType.edgesValues.(edgeName);
		s.props.elabelMap(edgeName) = hops.graph.properties.viewLabel.edgesValues.(edgeName);

		s.props.sourceMap(edgeName) = str2double(hops.graph.properties.Source.edgesValues.(edgeName));
		s.props.targetMap(edgeName) = str2double(hops.graph.properties.Target.edgesValues.(edgeName));

		if isfield(hops.graph.properties.IsLoop.edgesValues, edgeName)
			s.props.loopMap(edgeName) = true;
		else
			s.props.loopMap(edgeName) = false;
		end

		if strcmp(hops.graph.properties.Directional.edgesValues.(edgeName), 'True')
			s.props.dirMap(edgeName) = true;
		else
			s.props.dirMap(edgeName) = false;
		end
	end % edgeList loop

