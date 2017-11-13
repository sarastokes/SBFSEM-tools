function [neuronData, nodeData, edgeData, childData] = getNeuronOData(cellNum, source)
    % GETNEURONODATA  Import neuron directly from OData
    % Inputs:
    %   cellNum         Cell ID number
    %   source          'inferior', 'temporal' ('i', 't')
    % Outputs:
    %   neuron          struct containing neuron information
    %   nodeData        location info for each annotation
    %   edgeData        links between annotations
    %   childData       structs containing synapse information
    %         

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
    edgeData = fetchLinkData(cellNum);
    nodeData = fetchLocationData(cellNum);

    % get the IDs of all child structures
    childURL = getODataURL(cellNum, source, 'child');
    childData = readOData(childURL);
    if ~isempty(childData.value)
      	childData = struct2table(childData.value);
        childData.Tags = parseTags(childData.Tags);
        IDs = childData.ID;
        fprintf('Importing data for %u child structures\n', length(IDs));

        for ii = 1:length(IDs)
            links = parseLinkData(IDs(ii));
            if ~isempty(links)
                edgeData = cat(1, edgeData, links);
            end
            nodeData = cat(1, nodeData, parseLocationData(IDs(ii)));
        end  
    else
        childData = [];
    end
    
    edgeData = array2table(edgeData);
    edgeData.Properties.VariableNames = {'ID', 'A', 'B'};
    nodeData = array2table(nodeData);
    nodeData.Properties.VariableNames = {'ID', 'ParentID',...
        'VolumeX', 'VolumeY', 'Z', 'Radius', 'X', 'Y',...
        'OffEdge', 'Terminal', 'Geometry'};

    % support functions --------------------------------------------
    function Locs = parseLocationData(ID)
        locationURL = getODataURL(ID, source, 'location');
        importedData = readOData(locationURL);
        if ~isempty(importedData.value)
            Locs = zeros(size(importedData.value, 1), 11);
            Locs(:, 1) = vertcat(importedData.value.ID);
            Locs(:, 2) = vertcat(importedData.value.ParentID);
            Locs(:, 3) = vertcat(importedData.value.VolumeX);
            Locs(:, 4) = vertcat(importedData.value.VolumeY);
            Locs(:, 5) = vertcat(importedData.value.Z);
            Locs(:, 6) = vertcat(importedData.value.Radius);
            Locs(:, 7) = vertcat(importedData.value.X);
            Locs(:, 8) = vertcat(importedData.value.Y);
            Locs(:, 9) = vertcat(importedData.value.OffEdge);
            Locs(:, 10) = vertcat(importedData.value.Terminal);
            Locs(:, 11) = vertcat(importedData.value.TypeCode);
        else
            Locs = [];
            % this is actually important to track
            % will throw errors in vikingplot
            fprintf('IMPORTANT: No locations for c%u\n', ID);
            row = childData.ID == ID;
            childData.Label(row,:) = {'NULL'};
        end
    end
end
