function [n, groupNames] = getContributions(ID, source, synapses, visualize)
	% GETCONTRIBUTIONS
	%
	%

	if nargin < 3
		synapses = false;
	end

	if nargin < 4
		visualize = false;
	end


	usernames = getUsernames(ID, source);

	if synapses
		neuron = Neuron(ID, source, true);
		IDs = neuron.synapseIDs();
		for i = 1:numel(IDs)
			usernames = vertcat(getUsernames(IDs(i), source));
		end
	end

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
		figure();
		pie(n, groupNames);
	end
end

function usernames = getUsernames(ID, source)
	baseURL = getServiceRoot(source);
	baseURL = [baseURL, 'Structures(', num2str(ID),... 
		')/Locations?$select=Username'];

	data = readOData(baseURL);
	data = vertcat(data.value{:});
	usernames = vertcat(data.Username);
end