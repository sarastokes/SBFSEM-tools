classdef AnnotationSizes < sbfsem.analysis.NeuronAnalysis
% ANNOTATIONSIZES
% 
% Description:
%	A histogram of dendrite radius as a function of distance from soma
% 
% Methods:
% 	See NeuronAnalysis for information on using the core 3 methods:
%		constructor, doAnalysis, plot
%	and for accessing the specific key/value arguments with `help`
%
% See also:
%	SomaDistanceView, sbfsem.analysis.NeuronAnalysis
%
% History:
%	18Sept2018 - SSP
% --------------------------------------------------------------------

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
			% DOANALYSIS
			%	
			% Optional key/value inputs:
			%	nBins 		Number of histogram bins 
			% 				default lets matlab histcounts decide
			%	Plot 		Plot the output? (Default = true)
			%	Max 		Max annotation size to include (default = all)
			%				Do this to zoom in on a certain range
			%
			% Example:
			%	% Analyze only the annotations with > 3 micron radius
			%	obj.doAnalysis('Max', 3);
			
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
			% PLOT
			%
			% Optional key/value inputs:
			%	useDiameter 	Plot diameter instead of radius
			%					Default = false
			%	ax 				Axis handle to plot to 
			%					Default = new figure
			%	color 			Color to plot as (default = black)

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