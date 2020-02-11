function T = getContributions(ID, source, visualize)
	% GETCONTRIBUTIONS
	%
	% Description:
    %   Get the number of annotations per username for a Structure ID
    %
    % Syntax:
    %   T = getContributions(ID, source, visualize)
    %
    % Inputs:
    %   ID          Stucture ID number
    %   source      Volume name or abbreviation
    %   visualize   Plot result? (default = true)
    %
    % History:
    %   19Jul2018 - SSP
    %   19Nov2018 - SSP - Removed synapse option
    %   3Feb2020 - SSP - Fixed title overlap
    % ---------------------------------------------------------------------
    
    if nargin < 3
        visualize = true;
    end
    
    usernames = getUsernames(ID, source);
    nAnnotations = size(usernames, 1);
    usernames = cellstr(usernames);
    
    
    [groupIndex, groupNames] = findgroups(usernames);
    n = splitapply(@numel, usernames, groupIndex);
    
    [n, ind] = sort(n, 'descend');
    groupNames = groupNames(ind);
    
    fprintf('c%u annotators:\n', ID);
    for i = 1:numel(n)
        fprintf('\t%u - %s\n', n(i), groupNames{i});
    end
    
    if visualize
        ax = axes('Parent', figure('Name', sprintf('c%u Users', ID)));
        pie(n, ones(size(n)), groupNames);
        h = title(ax, sprintf('c%u - %u annotations', ID, nAnnotations));
        % Title always overlaps with labels
        ax.Position(2) = ax.Position(2) - 0.05;
        h.Position(2) = h.Position(2) + 0.1;
        if numel(groupNames) > 1
            colormap(pmkmp(numel(groupNames), 'cubicl'));
        end
    end
    
    T = table(groupNames, n, 'VariableNames', {'Username', 'Annotations'});
end

function usernames = getUsernames(ID, source)
	baseURL = getServiceRoot(source);
	baseURL = [baseURL, 'Structures(', num2str(ID),... 
		')/Locations?$select=Username,ID'];

	data = readOData(baseURL);
	data = vertcat(data.value{:});
	usernames = vertcat(data.Username);
    usernames = cellstr(usernames);
end