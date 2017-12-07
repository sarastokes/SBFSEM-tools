function [IDs, url] = queryLabels(str, source)
	% QUERYLABELS  Query OData for cell IDs with label
	%	Input:
	%		str   	cell label string
	%		source 	volume name
	%	Output:
	%		IDs 	array of matching cell IDs
	%
	%	Use:
	%		IDs = queryLabels('s-cone', 'i');
	% 4Dec2017 - SSP

	baseURL = getServiceRoot(source);
	url = [baseURL, sprintf('Structures?$filter=contains(Label,''%s'')&$select=ID', str)];

	data = webread(url, 'Timeout', 30);

	IDs = vertcat(data.value.ID);