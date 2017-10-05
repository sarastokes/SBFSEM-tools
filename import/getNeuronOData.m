function [neuronData, nodeData, edgeData, childData] = getNeuronOData(cellNum, source)
    % GETNEURONODATA  Import neuron directly from OData

    ip = inputParser();
    addRequired(ip, 'cellNum', @isnumeric);
    addRequired(ip, 'source', @(x) any(validateattributes(...
        lower(x), {'temporal', 'inferior', 'rc1', 'r', 'i', 't'})))
	fprintf('Beginning data import for c%u\n', cellNum);
    neuronURL = getODataURL(cellNum, source, 'neuron');
    try
    	neuronData = readOData(neuronURL);
    catch ME1
        % Often first run times out regardless of timeout setting
        if strcmp(ME1.identifier, 'MATLAB:webservices:Timeout')
            neuronData = readOData(neuronURL);
        end
    end
    edgeData = getLinkData(cellNum);
    nodeData = getLocationData(cellNum);

    % get the IDs of all child structures
    childURL = getODataURL(cellNum, source, 'child');
    childData = readOData(childURL);
    childData = rmfield(childData.value, {'Confidence',... 
    	'Notes', 'Verified', 'Created', 'Version' });
  	childData = struct2table(childData);
    childData.Tags = parseTags(childData.Tags);

    IDs = childData.ID;
    fprintf('Importing data for %u child structures\n', length(IDs));

    for ii = 1:length(IDs)
        links = getLinkData(IDs(ii));
        if ~isempty(links)
    	    edgeData = cat(1, edgeData, links);
        end
	    nodeData = cat(1, nodeData, getLocationData(IDs(ii)));
    end

    edgeData = array2table(edgeData);
    edgeData.Properties.VariableNames = {'ID', 'A', 'B'};
    nodeData = array2table(nodeData);
    nodeData.Properties.VariableNames = {'ID', 'ParentID',... 
        'VolumeX', 'VolumeY', 'Z', 'Radius', 'X', 'Y', 'OffEdge'};

    % support functions --------------------------------------------
    function Locs = getLocationData(ID)
        locationURL = getODataURL(ID, source, 'location');
        importedData = readOData(locationURL);
        if ~isempty(importedData.value)
            Locs = zeros(size(importedData.value, 1), 9);
            Locs(:, 1) = vertcat(importedData.value.ID);
            Locs(:, 2) = vertcat(importedData.value.ParentID);
            Locs(:, 3) = vertcat(importedData.value.VolumeX);
            Locs(:, 4) = vertcat(importedData.value.VolumeY);
            Locs(:, 5) = vertcat(importedData.value.Z);
            Locs(:, 6) = vertcat(importedData.value.Radius);
            Locs(:, 7) = vertcat(importedData.value.X);
            Locs(:, 8) = vertcat(importedData.value.Y);
            Locs(:, 9) = vertcat(importedData.value.OffEdge);
        else
            Locs = [];
            % this is actually important to track
            % will throw errors in vikingplot
            fprintf('IMPORTANT: No locations for c%u\n', ID);
            row = childData.ID == ID;
            childData.Label(row,:) = {'NULL'};
        end
    end

    function LocLinks = getLinkData(ID)
    	linkURL = getODataURL(ID, source, 'link');
    	importedData = readOData(linkURL);
        if ~isempty(importedData.value)
        	LocLinks = zeros(size(importedData.value, 1), 3);
        	LocLinks(:, 1) = repmat(ID, [size(importedData,1), 1]);
    	    LocLinks(:, 2) = vertcat(importedData.value.A);
    	    LocLinks(:, 3) = vertcat(importedData.value.B);
        else
            LocLinks = [];
        end
    end
end
