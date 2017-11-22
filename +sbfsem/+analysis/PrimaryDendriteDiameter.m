classdef PrimaryDendriteDiameter < sbfsem.analysis.NeuronAnalysis
    % PRIMARYDENDRITEDIAMETER
    % See analyzeDS.m for information on use
    %
    %   INPUTS:
    %		neuron 				neuron object
    %	OPTIONAL:
    %		dim 		[2]		2 or 3 dimensions
    %		ind 	    []	    rows to remove (axon, soma)
    %		nbins 	  [auto]	number of bins for histogram
    %		graph 	  [true]	whether to plot results
    %		search 	  [2 5]		primary dendrite search window
    %	OUTPUT:
    %		d 			structure containing stats
    %
    %	NOTES: search window will depend on bin count,
    %		which should typically be high (20 usually works)
    %		bin 1 is omitted assuming it's mostly the soma.
    %		Keep an eye on the search window printout which
    %		will show the how consistent the analysis is.
    %
    % 25Aug2017 - SSP - created from analyzeDS.m
    
    properties (Constant = true, Hidden = true)
        DisplayName = 'PrimaryDendriteDiameter'
    end
    
    methods
        function obj = PrimaryDendriteDiameter(neuron, varargin)
            validateattributes(neuron, {'sbfsem.Neuron'}, {});
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            
            obj.doAnalysis(varargin);
            obj.visualize();
        end
        
        function doAnalysis(obj, varargin)
            obj.data = analyzeDS(obj.target, varargin);
            
            ip = inputParser();
            addParameter(ip, 'dim', 2, @(x) ismember(x, [2 3]));
            addParameter(ip, 'ind', [], @isvector);
            addParameter(ip, 'nbins', [], @isnumeric);
            addParameter(ip, 'search', [2 5], @isvector);
            parse(ip, varargin{:});
            nbins = ip.Results.nbins;
            searchBins = ip.Results.search(1):ip.Results.search(2);
            
            % Get the soma location
            soma = getSomaXYZ(obj.target);
            % Remove rows for soma/axon
            T = obj.target.dataTable;
            if ~isempty(ip.Results.ind)
                T(ip.Results.ind,:) = [];
            end
            % Remove the synapse annotations
            row = strcmp(T.LocalName, 'cell');
            T = T(row, :);
            % Get the remaining locations
            xyz = T.XYZum;
            
            % Remove Z-axis if needed
            if ip.Results.dim == 2
                xyz = xyz(:, 1:2);
                soma = soma(:, 1:2);
            end
            
            % Get the distance of each annotation from the soma
            somaDist = fastEuclid2d(soma, xyz);
            fprintf('soma distances range from %.2f to %.2f\n',...
                min(somaDist), max(somaDist));
            
            % Create a histogram of soma distances
            if isempty(nbins)
                [n, edges, bins] = histcounts(somaDist);
            else
                [n, edges, bins] = histcounts(somaDist, nbins);
            end
            
            % Get the dendrite sizes
            dendrite = T.Size;
            
            % Prevent splitapply error for empty bins
            emptyBins = find(n == 0);
            % lots of empty bins is generally not a good sign
            fprintf('Found %u empty bins\n', numel(emptyBins));
            % make sure each bin is represented - even if its just 0
            if ~isempty(emptyBins)
                bins = cat(1, bins, emptyBins');
                dendrite = cat(1, dendrite, zeros(numel(emptyBins)));
            end
            
            % compute dendrite size stats per distance bin
            d.counts = n;
            d.edges = edges;
            d.avg = splitapply(@mean, dendrite, bins);
            d.std = splitapply(@std, dendrite, bins);
            d.sem = splitapply(@sem, dendrite, bins);
            d.median = splitapply(@median, dendrite, bins);
            % print some results
            fprintf('search window = %.2f to %.2f\n',...
                edges(searchBins(1)), edges(searchBins(2)));
            fprintf('mean diameter = %.2f +- %.2f\n',...
                mean(d.avg(searchBins)), mean(d.sem(searchBins)));
            fprintf('median diamter = %.2f\n',...
                mean(d.median(searchBins)));
            
            % save the params for later reference
            d.params.searchBins = searchBins;
            d.params.nbins = ip.Results.nbins;
            d.params.dim = ip.Results.dim;
            d.params.ind = ip.Results.ind;
            
            % save to object
            obj.data = d;
        end
        
        function fh = visualize(obj)
            % VISUALIZE  Plot the analysis results
            fh = figure('Name', sprintf('c%u dendrite analysis',...
                obj.target.cellData.cellNum));
            ax = axes('Parent', fh,...
                'Box', 'off', 'TickDir', 'out');
            hold on;
            errorbar(obj.data.edges(2:end), obj.data.avg, obj.data.sem,...
                'k', 'LineWidth', 1);
            plot(obj.data.edges(2:end), obj.data.median,...
                'b', 'LineWidth', 1);
            % keep this for easy copy to other plots
            plot(obj.data.edges(2:end), obj.data.avg,...
                'k', 'LineWidth', 1)
            legend(ax, 'mean', 'median');
            set(legend, 'EdgeColor', 'w', 'FontSize', 10);
            xlabel(ax, 'distance from soma (microns)');
            ylabel(ax, 'avg dendrite diameter (microns)');
            title(ax, sprintf('c%u',...
                obj.target.cellData.cellNum));
        end
    end
end
