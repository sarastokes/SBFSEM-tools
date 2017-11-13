function s = parseNodes(cellData)
	% INPUT: json file exported from tulip (see tulip2json.py)
	% 		cellData 		filepath + name as string
	%
	% 5May2017 - SSP - created
	% 10May2017 - SSP - updated to use local names
	% 16Jun2017 - SSP - added containers.Map, renamed to parseNodesEdges.m

	if ischar(cellData) && strcmp(cellData(end-3:end), 'json')
		fprintf('parsing with loadjson.m...');
		cellData = loadjson(cellData);
		fprintf('parsed\n');
	elseif ~isstruct(cellData) % could also supply output from loadjson..
		error('input filename as string or struct from loadjson()');
	end

	s.fileName = cellData.graph.attributes.file{1,2};
	s.parseDate = datestr(now);
	s.tulipData.edgesNumber = cellData.graph.edgesNumber;
	s.tulipData.nodesNumber = cellData.graph.nodesNumber;

	% init soma structure - assumes largest radius cell is the soma
	somaSize = 0;

	% get all the fieldnames with locations
	s.nodeList = fieldnames(cellData.graph.properties.LocationInViking.nodesValues);
	s.skeleton = cell(1,1);

	% init containers
	s.props.nameMap = containers.Map;
	s.props.iiMap = containers.Map;
	s.props.sizeMap = containers.Map;
	s.props.idMap = containers.Map;
	s.props.uniqueMap = containers.Map;
	s.props.parentMap = containers.Map;
	s.props.xyzMap = containers.Map; 
	s.props.synTagMap = containers.Map;
	s.props.synTypeMap = containers.Map;
	s.props.localNameMap = containers.Map;
	s.props.offEdgeMap = containers.Map;
	s.props.terminalMap = containers.Map;
	s.props.linkMap = containers.Map;

	initFlag = true;
	% local synapse name
	s.typeData.names = cell(1,1);
	% each synapse gets a unique parent ID
	s.typeData.parents = cell(1,1);
	% total found
	s.typeData.count = 0;
	% total with unique parent IDs
	s.typeData.uniqueCount = 0;
	% node id is number in structure - easier to work with than char IDs
	s.typeData.nodeIDs = cell(1,1);
	% one node id per unique synapse
	s.typeData.uniqueNodes = cell(1,1); 

	parentList = [];

	for ii = 1:length(s.nodeList)
		nodeName = char(s.nodeList{ii});
		s.props.nameMap(nodeName) = nodeName;
		s.props.iiMap(nodeName) = ii;
		s.props.parentMap(nodeName) =  str2double(cellData.graph.properties.ParentID.nodesValues.(s.nodeList{ii}));

		if isempty(intersect(s.props.parentMap(nodeName), parentList))
			parentList = [parentList, s.props.parentMap(nodeName)]; %#ok<AGROW>
			s.props.uniqueMap(nodeName) = true;
		end
		
		s.props.idMap(nodeName) = str2double(cellData.graph.properties.LocationID.nodesValues.(s.nodeList{ii}));

		s.props.synTypeMap(nodeName) =  lower(cellData.graph.properties.Type.nodesValues.(s.nodeList{ii}));
		% display(s.props.synTypeMap(nodeName));
		if isfield(cellData.graph.properties.StructureTags.nodesValues, nodeName);
			s.props.synTagMap(nodeName) = cellData.graph.properties.StructureTags.nodesValues.(nodeName);
		else
			s.props.synTagMap(nodeName) = cellData.graph.properties.StructureTags.nodeDefault;
		end

		viewSize = cellData.graph.properties.viewSize.nodesValues.(s.nodeList{ii});
		viewSize = viewSize(2:end-4);
		viewSize = regexp(viewSize, ',', 'split');
		viewSize = cellfun(@str2double, viewSize);
		s.props.sizeMap(nodeName) = viewSize(1);

		localName = getLocalName(s.props.synTypeMap(nodeName), s.props.synTagMap(nodeName));

		if ~strcmp(localName, 'cell')
			s = synCounter(s, localName, s.props.parentMap(nodeName), nodeName);
		else
			s.skeleton = cat(2, s.skeleton, nodeName);
			if viewSize(1) > somaSize
				s.somaNode = nodeName;
				somaSize = viewSize(1);
			end
		end

		loc = cellData.graph.properties.LocationInViking.nodesValues.(nodeName);
		loc(regexp(loc, '[XYZ:]')) = [];
		loc = regexp(loc, ' ', 'split');
		s.props.xyzMap(nodeName) = cellfun(@str2double, loc);

		if isfield(cellData.graph.properties.OffEdge.nodesValues, nodeName)
			s.props.offEdgeMap(nodeName) = true;
		end
		if isfield(cellData.graph.properties.Terminal.nodesValues, nodeName)
			s.props.terminalMap(nodeName) = true;
		end

		if isfield(cellData.graph.properties.NumLinkedStructures, nodeName)
			s.props.linkMap(nodeName) = str2double(cellData.graph.properties.NumLinkedStructures.nodesValues.(nodeName));
		else
			s.props.linkMap(nodeName) = 0;
		end
	end
	% each unique synapse has a different parent ID.
	% synapses spanning multiple sections should share a parent ID
	s.typeData.uniqueParents = cellfun(@unique, s.typeData.parents, 'UniformOutput', 0);

	% print synapse data to cmd line
	cellStats(s);


%% ------------------------------------------------- support functions ----

	function s = appendType(s, localName)
		% % local synapse name
			s.typeData.names = cat(2, s.typeData.names, localName);
		% each synapse gets a unique parent ID
			s.typeData.parents{1, end+1} = [];
		% total found
			s.typeData.count = cat(2, s.typeData.count, 0);
		% total with unique parent IDs
			s.typeData.uniqueCount = cat(2, s.typeData.uniqueCount, 0);
		% node id is number in structure - easier to work with than char IDs
			s.typeData.nodeIDs{1, end+1} = [];
		% one node id per unique synapse
			s.typeData.uniqueNodes{1, end+1} = [];
	end % appendType

	function s = synCounter(s, localName, parentID, nodeName)
			if initFlag 
				fprintf('new synapse type %s\n', localName);
				s.typeData.names{1} = localName; 
				ind = 1; initFlag = false;
			else
				ind = find(ismember(s.typeData.names, localName));
			end
			if isempty(ind)
				% catch the ones i'm forgetting
				fprintf('new synapse type %s\n', localName);
				s = appendType(s, localName);
				ind = find(ismember(s.typeData.names, localName));
			end
			% this can be condensed once we figure out the info typically needed
			s.typeData.count(ind) = s.typeData.count(ind) + 1;
			if isempty(s.typeData.parents{ind})
				s.typeData.uniqueCount(ind) = s.typeData.uniqueCount(ind) + 1;
				% s.typeData.uniqueNodes{1, ind} = cell(1,1);
				s.typeData.uniqueNodes{1, ind} = {nodeName};
			end
			if isempty(find(s.typeData.parents{ind} == parentID))
				s.typeData.uniqueCount(ind) = s.typeData.uniqueCount(ind) + 1;
				s.typeData.uniqueNodes{1, ind} = cat(2, s.typeData.uniqueNodes{1,ind}, nodeName);
			end
			s.typeData.parents{ind} = cat(2, s.typeData.parents{ind}, parentID);
			s.typeData.nodeIDs{ind} = cat(2, s.typeData.nodeIDs{ind}, nodeName);
	end % synCounter
end % parseNodesEdges