classdef AnnotationSizes < sbfsem.analysis.NeuronAnalysis

	properties (Constant = true, Hidden = true)
		DisplayName = 'AnnotationSizes';
	end

	methods
		function obj = AnnotationSizes(neuron, varargin)
			validateattributes(neuron, {'NeuronAPI'}, {});
			obj@sbfsem.analysis.NeuronAnalysis(neuron);

			obj.data.sizes = neuron.nodes.Rum;
			obj.doAnalysis(varargin{:});
		end

		function doAnalysis(obj, varargin)
			ip = inputParser();
			ip.CaseSensitive = false;
			addParameter(ip, 'nBins', [], @isnumeric);
			addParameter(ip, 'Plot', true, @islogical);
			addParameter(ip, 'Max', [], @isnumeric);
			parse(ip, varargin{:});

			nBins = ip.Results.nBins;

			data = obj.data.sizes;
			if ~isempty(ip.Results.Max)
				data = data(data < ip.Results.Max);
				fprintf('Keeing %u of %u annotations under %.3g\n',...
					numel(data), numel(obj.data.sizes), ip.Results.Max);
			end

			if isempty(nBins)
				[counts, edges] = histcounts(data);
			else
				[counts, edges] = histcounts(data, nBins);
			end

			obj.data.bins = edges(2:end) - (edges(2)-edges(1))/2;
			obj.data.counts = counts;

			if ip.Results.Plot
				obj.plot();
			end
		end

		function plot(obj, varargin)
			ip = inputParser();
			ip.CaseSensitive = false;
			addParameter(ip, 'ax', [], @ishandle);
			addParameter(ip, 'Color', 'k', @(x) ischar(x) || isvector(x));
			parse(ip, varargin{:});

			if isempty(ip.Results.ax)
				ax = axes('Parent', figure());
			else
				ax = ip.Results.ax;
			end
			hold(ax, 'on');

			plot(ax, obj.data.bins, obj.data.counts,...
				'Color', ip.Results.Color, 'LineWidth', 1);
			xlabel('Radius (microns)');
			ylabel('Number of annotations');
		end
	end
end