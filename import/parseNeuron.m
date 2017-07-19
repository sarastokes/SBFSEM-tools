function s = parseNeuron(cellData, source)
	% INPUT: json file exported from tulip (see tulip2json.py)
	% 		cellData 		filepath + name as string
	%		source			'inferior', 'temporal', 'rc1'
	%
	% 5May2017 - SSP - created
	% 10May2017 - SSP - updated to use local names
	% 16Jun2017 - SSP - added containers.Map, renamed to parseNodesEdges.m
	% 22Jun2017 - SSP - changed to table structure
	% 16Jul2017 - SSP - added source requirement, XYZ units, RC1 support

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

	% init the table variables
	XYZ = [];
	LocationID = [];
	LocalName = cell(1,1);
	ParentID = [];
	SynType = cell(1,1);
	SynTag = cell(1,1);
	Size = [];
	Unique = [];
    SynNum = [];
	OffEdge = [];
	Terminal = [];
	UUID = cell(1,1);

	% init the synapse variables
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
	% track unique parentIDs
	parentList = [];
    uInd = 0;

	% save some space
	c = cellData.graph.properties;

	for ii = 1:length(s.nodeList)
		nodeName = char(s.nodeList{ii});
		UUID = cat(1, UUID, nodeName);
		p = str2double(c.ParentID.nodesValues.(nodeName));
		ParentID = cat(1, ParentID, p);

        if isempty(intersect(p, parentList))
            parentList = [parentList, p]; %#ok<AGROW>
            Unique = cat(1, Unique, 1);
            % increment the unique synapse count
            uInd = uInd + 1;
        else
            Unique = cat(1, Unique, 0);
        end
        SynNum = cat(1, SynNum, uInd);

		LocationID = cat(1, LocationID, str2double(c.LocationID.nodesValues.(nodeName)));
		
		SynType = cat(1, SynType, lower(c.Type.nodesValues.(nodeName)));
        if isfield(c.StructureTags, 'nodesValues') && isfield(c.StructureTags.nodesValues, nodeName)
            SynTag = cat(1, SynTag, c.StructureTags.nodesValues.(nodeName));
        else
            SynTag = cat(1, SynTag, '_');
        end
        
        try
           LocalName = cat(1, LocalName, getLocalName(SynType{end}, SynTag{end}));
        catch
            fprintf('No local name assigned for %s, %s\n', SynType{end}, SynTag{end});
        end
 
		sz = c.viewSize.nodesValues.(nodeName);
		sz = sz(2:end-4);
		sz = regexp(sz, ',', 'split');
		Size = cat(1, Size, str2double(sz(1)));

		if ~strcmp(LocalName{end}, 'cell')
			s = synCounter(s, LocalName{end}, ParentID(end), nodeName);
		else
			s.skeleton = cat(2, s.skeleton, nodeName);
			if Size(end, 1) > somaSize
				s.somaNode = nodeName;
				somaSize = Size(end, 1);
			end
		end

		loc = c.LocationInViking.nodesValues.(nodeName);
		loc(regexp(loc, '[XYZ:]')) = [];
		loc = regexp(loc, ' ', 'split');
		XYZ = cat(1, XYZ, cellfun(@str2double, loc));

        if isfield(c.OffEdge, 'nodesValues') && isfield(c.OffEdge.nodesValues, nodeName)
            OffEdge = cat(1, OffEdge, true);
        else
            OffEdge = cat(1, OffEdge, false);
        end
        
        if isfield(c.Terminal, 'nodesValues') && isfield(c.Terminal.nodesValues, nodeName)
            Terminal = cat(1, Terminal, true);
        else
            Terminal = cat(1, Terminal, false);
        end
	end % node loop

	% each unique synapse has a different parent ID.
	% synapses spanning multiple sections should share a parent ID
	s.typeData.uniqueParents = cellfun(@unique, s.typeData.parents, 'UniformOutput', 0);


	SynTag(1,:) = []; SynType(1,:) = [];
	LocalName(1,:) = []; UUID(1,:) = [];
	s.skeleton(:,1) = [];
	switch lower(source)
		case 'temporal'
			XYZum = bsxfun(@times, XYZ, [0.005 0.005 0.07]);
		case 'inferior'
			XYZum = bsxfun(@times, XYZ, [0.005 0.005 0.09]);
		case 'rc1'
			XYZum = bsxfun(@times, XYZ, [0.00218 0.00218 0.08])
	end

	% arrange the data table
	s.dataTable = table(LocationID, LocalName, XYZ, XYZum,... 
		ParentID, SynType, SynTag, Size,... 
		Unique, SynNum, OffEdge, Terminal, UUID);

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

