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
    
    properties (SetAccess = private)
        numAnnotations
        analysisParams
    end
    
    properties (Constant = true, Hidden = true)
        DisplayName = 'AnnotationSizes';
    end
    
    methods
        function obj = AnnotationSizes(neuron, varargin)
            validateattributes(neuron, {'sbfsem.core.NeuronAPI'}, {});
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            
            obj.data.sizes = neuron.nodes.Rum;
            obj.numAnnotations = numel(obj.data.sizes);
            obj.doAnalysis(varargin{:});
        end
        
        function doAnalysis(obj, varargin)
            % DOANALYSIS
            %
            % Optional key/value inputs:
            %	nBins           Number of histogram bins
            %                   default lets matlab histcounts decide
            %   BinWidth        Passed to histcounts 'BinWidth'
            %                   NOTE: Overrides nBins!
            %	Plot            Plot the output? (Default = true)
            %	Max 			Max radius to include (default = all)
            %                   Will be passed to histcounts 'BinLimits'
            %   Normalization   See histcounts input 'Normalization'
            %                   Default = 'counts'
            % Can also pass key/value inputs to apply to plot()
            %
            % Example:
            %	% Analyze only the annotations with > 3 micron radius
            %	obj.doAnalysis('Max', 3);
            
            ip = inputParser();
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'nBins', [], @isnumeric);
            addParameter(ip, 'BinWidth', [], @isnumeric);
            addParameter(ip, 'Normalization', 'count', @ischar);
            addParameter(ip, 'Plot', true, @islogical);
            addParameter(ip, 'Max', max(obj.data.sizes), @isnumeric);
            parse(ip, varargin{:});
            
            obj.analysisParams = ip.Results;
            
            nBins = ip.Results.nBins;
            binWidth = ip.Results.BinWidth;
            binLimits = [0, ip.Results.Max];
            
            data = obj.data.sizes;
            if ~isempty(ip.Results.Max)
                data = data(data < ip.Results.Max);
                fprintf('Keeing %u of %u annotations under %.3g\n',...
                    numel(data), numel(obj.data.sizes), ip.Results.Max);
            end
            
            if ~isempty(binWidth)
                [counts, edges] = histcounts(data,...
                    'BinWidth', binWidth,...
                    'Normalization', ip.Results.Normalization,...
                    'BinLimits', binLimits);
            elseif ~isempty(nBins)
                [counts, edges] = histcounts(data, nBins,...
                    'BinLimits', binLimits,...
                    'Normalization', ip.Results.Normalization);
            else
                [counts, edges] = histcounts(data);
            end
            
            obj.data.bins = edges(2:end) - (edges(2)-edges(1))/2;
            obj.data.counts = counts;
            
            if ip.Results.Plot
                obj.plot(ip.Unmatched);
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
            addParameter(ip, 'Diameter', false, @islogical);
            parse(ip, varargin{:});
            
            if isempty(ip.Results.ax)
                ax = axes('Parent', figure('Renderer', 'painters'));                           
                figPos(ax.Parent, 0.6, 0.6);
            else
                ax = ip.Results.ax;
            end
            hold(ax, 'on');
            
            bins = obj.data.bins;
            if ip.Results.Diameter
                bins = bins*2;
            end
            
            plot(ax, bins, obj.data.counts,...
                'Color', ip.Results.Color, 'LineWidth', 1,...
                'DisplayName', num2str(obj.ID));
            if ip.Results.Diameter
                xlabel(ax, 'Diameter (microns)');
            else
                xlabel(ax, 'Radius (microns)');
            end
            
            if strcmp(obj.analysisParams.Normalization, 'cdf')
                ylabel(ax, '% Annotations');
                ylim(ax, [0, 1]);
            else
                ylabel(ax, 'Number of annotations');
            end
        end
    end
end