classdef TraceMosaic < handle

	properties (Access = private)
		fname
		dateCreated
		labelMatrix
		scaleFac = 0.2276
	end

	properties (SetAccess = private, GetAccess = public)
		idx = containers.Map
		data
		analysis
	end
	
	methods
		function obj = TraceMosaic(fname, processImage)
			% TRACEMOSAIC

			if nargin < 2
				processImage = true;
			end

			if ischar(fname)
				im = imread(fname);
				im = imbinarize(rgb2gray(im2double(im)));
				im = bwareaopen(im, 1000);
				obj.fname = fname;
			elseif ~islogical(fname)
				fprintf('Input should be file name or binary image matrix\n');
				return;
			else
				obj.fname = [];
			end

			obj.dateCreated = datestr(now);

			data = table(1:length(B), B);
			data.Properties.VariableNames = {'No', 'Bounds'};
		end % constructor

		function baseAnalysis(obj)
			% BASEANALYSIS  Initial analysis run on traces
			stats = ('table', L, 'Centroid', 'BoundingBox',...
				'EquivDiameter', 'MajorAxisLength', 'MinorAxisLength');
		end % baseAnalysis

		function groupAnalysis(obj, dataName, varargin)
			% GROUPANALYSIS  Run analysis on a specific

			ip = inputParser();
			addRequired(ip, 'dataName', @(x) any(validatestring(lower(x),... 
				obj.Properties.VariableNames)));
			addParameter(ip, 'idxName', [], @(x) any(validatestring(lower(x),...
				obj.idx.Keys)));
			parse(ip, dataName, varargin{:});
			dataName = ip.Results.dataName;
			idxName = ip.Results.idxName;

			if isempty(idxName)
				ind = 1:height(obj.data);
			else
				ind = obj.idx(idxName)
			end

			T = table(dataName, )
			if isempty(obj.analysis)
				obj.analysis = T;
				obj.analysis.Properties.VariableNames = {'Name', 'idxName',... 
				'Mean', 'SEM', 'N', 'H', 'P', 'Idx', 'Date'};
			else
				obj.analysis = [obj.analysis; T];
			end

		end % groupAnalysis
	end % methods

	methods (Private)
		function setIdx(n, idxName, otherName)
			% SETIDX  Assign an index to specific cones
			% Optional input otherName: applied to values not in n
			if ismember(idxName, idx.keys)
				selection = questdlg(sprintf('Overwrite existing index named %s', idxName),...
					'Index overwrite dialog',...
					{'Yes', 'No', 'Yes'});
				if strcmp(selection, 'No')
					return;
				end
			end
			obj.idx(idxName) = n;
		end % setIdx
	end % methods private
end % classdef