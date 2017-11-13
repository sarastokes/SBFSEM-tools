function [xyz, fh] = IPLMarker(source, visualize)
	% IPLMARKER  Query OData for IPL markers, make surface
	% Inputs:
	%	source 		volume name or abbreviation
	% Outputs: 		xyz locations of IPL-INL markers
	% 
	% 3Nov2017 - SSP

	volumeName = validateSource(source);
	baseURL = [getServerName(), volumeName, '/OData/'];

	if nargin < 2
		visualize = false;
	else
		assert(islogical(visualize), 'visualize is t/f');
	end

	% Return the IDs of the INL-IPL marker Structures
	data = readOData([baseURL,...
		'Structures?$filter=TypeID eq 224&$select=ID']);

	markerIDs = struct2array(data.value);
	fprintf('Returned %u IPL-INL markers\n',...
		numel(markerIDs));

	xyz = [];
	for i = 1:numel(markerIDs)
		data = readOData([baseURL,... 
			'Structures(', num2str(markerIDs(i)) ')',...
			'/Locations?$select=X,Y,Z']);
		xyz = cat(1, xyz, struct2array(data.value));
	end

	% Convert coordinates to microns
	xyz = viking2micron(xyz, source);

	if visualize
		fh = sbfsem.ui.FigureView(1);
		surf(fh.ax, xyz);
		shading('flat');
		fh.setColormap('redblue');
		fh.title('IPL Marker Surface');
		fh.labelXYZ();
	end
