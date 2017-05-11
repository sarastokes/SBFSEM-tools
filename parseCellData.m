function s = parseCellData(cellData)
	% INPUT: json file exported from tulip (see tulip2json.py)
	% 		cellData 		filepath + name as string
	%
	% USE:
	% s = parseCellData('c:\users\...\filename.json');
	%
	% 5May2017 - SSP - created

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

	% get all the fieldnames with locations
	s.nodeList = fieldnames(cellData.graph.properties.LocationInViking.nodesValues);

	for ii = 1:length(s.nodeList)
		s.nodes(ii).nodeName = s.nodeList{ii};
		s.nodes(ii).locationID = str2double(cellData.graph.properties.LocationID.nodesValues.(s.nodeList{ii}));

		s.nodes(ii).parentID = str2double(cellData.graph.properties.ParentID.nodesValues.(s.nodeList{ii}));

		s.nodes(ii).synType =  lower(cellData.graph.properties.Type.nodesValues.(s.nodeList{ii}));

		% structure tags will be combined with synapse type to get a single specific synapse variable. both will be kept, for now at least
		if isfield(cellData.graph.properties.StructureTags.nodesValues, s.nodeList{ii})
			s.nodes(ii).structureTags = cellData.graph.properties.StructureTags.nodesValues.(s.nodeList{ii});
		else
			s.nodes(ii).structureTags = cellData.graph.properties.StructureTags.nodeDefault;
		end

		if ~strcmp(s.nodes(ii).synType, 'cell')
			s = synCounter(s, s.nodes(ii).synType, s.nodes(ii).parentID, ii);
		end

		% get vector from XYZ location string
		loc = cellData.graph.properties.LocationInViking.nodesValues.(s.nodeList{ii});
		loc(regexp(loc, '[XYZ:]')) = [];
		loc = regexp(loc, ' ', 'split');
		s.nodes(ii).locationXYZ = cellfun(@str2double, loc);

		% get viewsize vector XY from string
		% NOTE: Z is always 75 so not storing that
		viewSize = cellData.graph.properties.viewSize.nodesValues.(s.nodeList{ii});
		viewSize = viewSize(2:end-4);
		viewSize = regexp(viewSize, ',', 'split');
		s.nodes(ii).viewSize = cellfun(@str2double, viewSize);

		% s.nodes(ii).terminal = cellData.graph.properties.Terminal.nodesValues;

		% get properties that only exist for some nodes
		% might skip the false ones eventually to save space
		if isfield(cellData.graph.properties.OffEdge.nodesValues, s.nodeList{ii})
			s.nodes(ii).offedge = true;
		else
			s.nodes(ii).offedge = false;
		end
		if isfield(cellData.graph.properties.Terminal.nodesValues, s.nodeList{ii})
			s.nodes(ii).terminal = true;
		else
			s.nodes(ii).terminal = false;
		end

		if isfield(cellData.graph.properties.NumLinkedStructures, s.nodeList{ii})
			s.nodes(ii).numLinked = str2double(cellData.graph.properties.NumLinkedStructures.nodesValues.(s.nodeList{ii}));
		else
			s.nodes(ii).numLinked = 0;
		end
	end
	s.typeData.uniqueParents = cellfun(@unique, s.typeData.parents, 'UniformOutput', 0);

	% % keep only the synapses the cell acutally has
	% [~,ind] = find(s.typeData.count);
	% s.typeData = structfun(@(x) (x(1,ind)), s.typeData, 'UniformOutput', false);
end

%% support functions
	function s = appendType(s, localName)
		% local synapse name
		s.typeData.names = cat(2, s.typeData.names, localName);
		% each synapse gets a unique parent ID
		s.typeData.parents = cat(2, s.typeData.parents, []);
		% total found
		s.typeData.count = cat(2, s.typeData.count, 0);
		% total with unique parent IDs
		s.typeData.uniqueCount = cat(2, s.typeData.uniqueCount, 0);

		% node id is number in structure - easier to work with than char IDs
		s.typeData.nodeIDs = cat(2, s.typeData.nodeIDs, []);
		s.typeData.uniqueNodes = cat(2, s.typeData.uniqueNodes, []);
	end

	function s = synCounter(s, localName, parentID, nodeInd)
			ind = find(ismember(s.typeData.names, localName));
			if isempty(ind)
				% catch the ones i'm forgetting
				fprintf('new synapse type %s\n', localName);
				s = appendType(s, localName);
			end
			% this can be condensed once we figure out the info typically needed
			s.typeData.count(ind) = s.typeData.count(ind) + 1;
			if isempty(s.typeData.parents{ind}) || isempty(find(s.typeData.parents{ind}==parentID))
				s.typeData.uniqueCount(ind) = s.typeData.uniqueCount(ind) + 1;
				s.typeData.uniqueNodes{ind} = cat(2, s.typeData.uniqueNodes{ind}, nodeInd);
			end
			s.typeData.parents{ind} = cat(2, s.typeData.parents{ind}, parentID);
			s.typeData.nodeIDs{ind} = cat(2, s.typeData.nodeIDs{ind}, nodeInd);
	end