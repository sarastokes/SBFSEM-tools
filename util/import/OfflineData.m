classdef OfflineData < handle
	% not recommended but is an option

	properties
		nodeTable
		edgeTable
	end

	methods
		function obj = OfflineData(varargin)
			ip = inputParser();
			addParameter(ip, 'source', [], @(x) any(validateattributes(...
				lower(x), {'i', 't', 'r', 'inferior', 'temporal', 'rc1'})));
			addParameter(ip, 'nodes', [], @ismatrix(x));
			addParameter(ip, 'edges', [], @ismatrix(x));
			parse(ip, varargin{:});
			if ~isempty(ip.Results.nodes)
				nodeTable = array2table(ip.Results.nodes);
			else
				str = getODataURL([], ip.Results.source, 'location');
			end
			if ~isempty(ip.Results.edges)
				edgeTable = array2table(ip.Results.edges);
			else
				str = getODataURL([], ip.Results.source, 'link');
			end
		end % constructor
	end % methods
end