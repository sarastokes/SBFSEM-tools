function [neuronData, nodeData, edgeData, childData] = getNeuronOData(cellNum, source)
    % GETNEURONODATA  Import neuron directly from OData

    ip = inputParser();
    addRequired(ip, 'cellNum', @isnumeric);
    addRequired(ip, 'source', @(x) any(validateattributes(...
        lower(x), {'temporal', 'inferior', 'rc1', 'r', 'i', 't'})))
	fprintf('Beginning data import for c%u\n', cellNum);
    neuronURL = getODataURL(cellNum, source, 'neuron');
	neuronData = webread(neuronURL,... 
        'Timeout', 30,... 
		'ContentType', 'json',... 
		'CharacterEncoding', 'UTF-8');
    edgeData = getLinkData(cellNum);
    nodeData = getLocationData(cellNum);

    % get the IDs of all child structures
    childURL = getODataURL(cellNum, source, 'child');
    childData = webread(childURL,... 
        'Timeout', 30,... 
		'ContentType', 'json',... 
		'CharacterEncoding', 'UTF-8');
    childData = rmfield(childData.value, {'Confidence',... 
    	'Notes', 'Verified', 'Created', 'Version' });
   	% {'ID', 'TypeID', 'Tags', 'Label', 'ParentID', 'Username', 'LastModified'});
  	childData = struct2table(childData);	
%   	for ii = 1:height(childData)
%   		if ~isempty(childData.Tags(ii,:))
% 	  		ind = strfind(childData.Tags{ii,:}, '"');
% 	  		ind = reshape(ind, 2, numel(ind));
% 	  		tag = childData.Tags{ii,:};
% 	  		str = [];
% 	  		for jj = 1:size(ind,2)
% 	  			str = [str, tag(ind(1, jj+1):ind(2, jj-1)), ' ']; %#ok<AGROW>
% 	  		end
% 	  		childData.Tags(ii,:) = str(1:end-1);
% 	  	end
%   	end

    IDs = childData.ID;
    fprintf('Importing data for %u child structures\n', length(IDs));

    for ii = 1:length(IDs)
	    % edgeData = cat(1, edgeData, getLinkData(IDs(ii)));
	    nodeData = cat(1, nodeData, getLocationData(IDs(ii)));
    end

    % support functions
    function T = getCellData(ID)
        cellURL = getODataURL(ID, source, 'neuron');
        T = webread(cellURL,...
            'Timeout', 30,...
            'ContentType', 'json',...
            'CharacterEncoding', 'UTF-8');
        T = struct2table(T);
    end

    function LocLinks = getLinkData(ID)
    	linkURL = getODataURL(ID, source, 'link');
    	importedData = webread(linkURL,... 
            'Timeout', 30,... 
            'ContentType', 'json',... 
            'CharacterEncoding', 'UTF-8');
    	fprintf('c%u - location link data imported\n', ID);
    	LocLinks = zeros(size(importedData.value, 1), 3);
    	LocLinks(:, 1) = ID;
    	LocLinks(:, 2) = vertcat(importedData.value.A);
    	LocLinks(:, 3) = vertcat(importedData.value.B);
    end

    function Locs = getLocationData(ID)
        locationURL = getODataURL(ID, source, 'location');
    	importedData = webread(locationURL,... 
            'Timeout', 30,... 
            'ContentType', 'json',... 
            'CharacterEncoding', 'UTF-8');
		Locs = zeros(size(importedData.value, 1), 12);
		Locs(:, 1) = vertcat(importedData.value.ID);
	    Locs(:, 2) = vertcat(importedData.value.ParentID);
	    Locs(:, 3) = vertcat(importedData.value.VolumeX);
	    Locs(:, 4) = vertcat(importedData.value.VolumeY);
	    Locs(:, 5) = vertcat(importedData.value.Z);
	    Locs(:, 6) = vertcat(importedData.value.Radius);
	    Locs(:, 7) = vertcat(importedData.value.X);
	    Locs(:, 8) = vertcat(importedData.value.Y);
    end
end
