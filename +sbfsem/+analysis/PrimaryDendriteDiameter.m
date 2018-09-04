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
    %   See also: sbfsem.ui.PrimaryDendriteDiameter.m, analyzeDS.m
    %
    % 25Aug2017 - SSP - created from analyzeDS.m
    
    properties (Constant = true, Hidden = true)
        DisplayName = 'PrimaryDendriteDiameter';
    end
    
    methods
        function obj = PrimaryDendriteDiameter(neuron, varargin)
            validateattributes(neuron, {'NeuronAPI'}, {});
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            
            obj.doAnalysis(varargin{:});
            % obj.visualize();
        end
        
        function doAnalysis(obj, varargin)
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
            T = obj.target.getCellNodes;
            if ~isempty(ip.Results.ind)
                T(ip.Results.ind,:) = [];
            end
            % Get the remaining locations
            xyz = T.XYZum;
            
            % Get the distance of each annotation from the soma
            if ip.Results.dim == 2
                % Remove Z-axis
                xyz = xyz(:, 1:2);
                soma = soma(:, 1:2);
                somaDist = fastEuclid2d(soma, xyz);
            else
                somaDist = fastEuclid3d(soma, xyz);
            end
            
            fprintf('soma distances range from %.2f to %.2f\n',...
                min(somaDist), max(somaDist));
            
            % Create a histogram of soma distances
            if isempty(nbins)
                [n, edges, bins] = histcounts(somaDist);
                fprintf('Using %u bins\n', numel(n));
            else
                [n, edges, bins] = histcounts(somaDist, nbins);
            end
            
            % Get the dendrite sizes
            dendrite = T.Rum;
            
            % Prevent splitapply error for empty bins
            emptyBins = find(n == 0);
            % Make sure each bin is represented by setting empty bins to 0
            if ~isempty(emptyBins)
                % Lots of empty bins is generally not a good sign
                fprintf('Found %u empty bins\n', numel(emptyBins));
                bins = cat(1, bins, emptyBins');
                dendrite = cat(1, dendrite, zeros(numel(emptyBins)));
            end
            
            % Compute dendrite size stats per distance bin
            h.counts = n';
            h.edges = edges(2:end)';
            h.avg = splitapply(@mean, dendrite, bins);
            h.std = splitapply(@std, dendrite, bins);
            h.sem = splitapply(@sem, dendrite, bins);
            h.median = splitapply(@median, dendrite, bins);
            
            % Compute stats on just the search window
            d.searchWindow = [edges(searchBins(1)), edges(searchBins(2))];
            d.mean = mean(h.avg(searchBins));
            d.sem = mean(h.sem(searchBins));
            d.median = mean(h.median(searchBins));
            d.n = sum(h.counts(searchBins));
                        
            % Print some results
            fprintf('c%u\n', obj.target.ID);
            fprintf('search window = %.2f to %.2f\n', d.searchWindow);
            fprintf('analysis includes %u annotations\n', d.n);
            fprintf('mean radius = %.2f +- %.2f\n', d.mean, d.sem);
            fprintf('median diamter = %.4f\n', 2*d.median);
            
            % Save the params for later reference
            d.params.searchBins = searchBins;
            d.params.nbins = ip.Results.nbins;
            d.params.dim = ip.Results.dim;
            d.params.ind = ip.Results.ind;
            
            % Save to object
            obj.data = h;
            obj.data.inWindow = d;
        end
        
        function fh = plot(obj)
            % VISUALIZE  Plot the analysis results
            fh = figure('Name', sprintf('c%u dendrite analysis',...
                obj.target.ID));
            ax = axes('Parent', fh,...
                'Box', 'off', 'TickDir', 'out');
            hold on;
            errorbar(obj.data.edges, obj.data.avg, obj.data.sem,...
                'k', 'LineWidth', 1);
            plot(obj.data.edges, obj.data.median,...
                'b', 'LineWidth', 1);
            % keep this for easy copy to other plots
            plot(obj.data.edges, obj.data.avg,...
                'k', 'LineWidth', 1)
            legend(ax, 'mean', 'median');
            set(legend, 'EdgeColor', 'w', 'FontSize', 10);
            xlabel(ax, 'distance from soma (microns)');
            ylabel(ax, 'avg dendrite diameter (microns)');
            title(ax, sprintf('c%u',...
                obj.target.ID));
        end
    end
end
