classdef NeuronGroup < handle
% NEURONGROUP  Holds an array of related Neurons

    
    properties (SetAccess = private)
        neurons
        IDs
        analyses = containers.Map();
        source
        description
        plotColor = [0.6 0.6 0.6];
    end
    
    methods
        function obj = NeuronGroup(neurons, source)
            obj.source = validateSource(source);
            switch class(neurons)
                case 'double'
                    obj.IDs = neurons;
                    obj.neurons = [];
                    for i = 1:numel(obj.IDs)
                        obj.neurons = cat(1, obj.neurons,...
                            sbfsem.Neuron(obj.IDs(i), obj.source));
                    end
                case 'sbfsem.Neuron'
                    obj.IDs = arrayfun(@(x) x.ID, neurons);
                    obj.neurons = neurons;
            end
        end

        function add(obj, neuron)
            % ADD  Append more neurons
            % Input:
            %   neuron      ID numbers or Neurons
            % TODO: consolidate constructor and add
            if isa(neuron, 'sbfsem.Neuron')
                for i = 1:numel(neuron)
                    obj.IDs = cat(1, obj.IDs, neuron);
                    for i = 1:numel(obj.IDs)
                        obj.neurons = cat(1, obj.neurons,...
                            sbfsem.Neuron(obj.IDs(i), obj.source));
                    end
                end
            else
                obj.IDs = cat(2, obj.IDs, arrayfun(@(x) x.ID, neuron));
                obj.neurons = cat(1, obj.neurons, neuron);
            end
        end

        function describe(obj, str, overwrite)
            % DESCRIBE  Add text explaining the NeuronGroup's purpose
            % Inputs:
            %   str         char    NeuronGroup description
            %   overwrite   bool    default = false

            if nargin < 3
                overwrite = false;
            else
                assert(islogical(overwrite), 'Overwrite = t/f');
            end

            if ~isempty(obj.description) && ~overwrite
                warning('Existing description, set overwrite to true');
                return;
            else
                obj.description = str;
            end
        end

        function setPlotColor(obj, plotColor)
            validateattributes(plotColor, {'char', 'double'}, {});
            obj.plotColor = plotColor;
        end
        
        % Some common group methods
        function [somaSizes, validIDs] = somaDiameter(obj, validateSizes)
            
            if nargin < 2
                validateSizes = false;
            end
            
            somaSizes = cell2mat(arrayfun(@(x) x.getSomaSize(true),...
                obj.neurons, 'UniformOutput', false));
            
            % Check for incomplete neurons
            if validateSizes
                validSomas = somaSizes > 5;
                fprintf('%u of %u neurons had valid soma sizes\n',...
                    nnz(validSomas), numel(somaSizes));
                validSomaSizes = somaSizes(validSomas);
                validIDs = obj.IDs(validSomas);
                somaSizes = validSomaSizes;
            else
                validIDs = obj.IDs;
            end
            % Print mean +- sem (n)
            printStat(somaSizes, true);
        end

        function fh = somaPlot(obj, varargin)

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'Color', obj.plotColor, @(x) isvector(x) || isvector(x));
            addParameter(ip, 'LineWidth', 1, @isnumeric);
            addParameter(ip, 'addLabel', false, @islogical);
            parse(ip, varargin{:});

            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
            else
                ax = ip.Results.ax;
            end

            [somaSizes, validIDs] = obj.somaDiameter(true);

            validNeurons = [];
            for i = 1:numel(obj.neurons)
                if ismember(obj.neurons(i).ID, validIDs)
                    validNeurons = cat(1, validNeurons, obj.neurons(i));
                end
            end
            xyz = cell2mat(arrayfun(@(x) x.getSomaXYZ, validNeurons,...
                'UniformOutput', false));

            for i = 1:numel(validNeurons)
                viscircles(ax, xyz(i, 1:2), somaSizes(i),...
                    'LineWidth', ip.Results.LineWidth,... 
                    'EdgeColor', ip.Results.Color);
                hold on; axis equal;
            end
            if ip.Results.addLabel
                for i = 1:numel(validNeurons)
                    text(ax, xyz(i,1), xyz(i,2),...
                        num2str(validNeurons(i).ID),...
                        'FontSize', 9,...
                        'HorizontalAlignment', 'center');
                end
            end
        end

        function arborArea(obj, somaIndex)
            % Not ready yet
            if nargin < 2
                somaIndex = 'both';
            else
                somaIndex = validatestring(somaIndex,...
                    {'both', 'above', 'below'});
            end
            % Get the Z sections
            xyz = cell2mat(arrayfun(@(x) x.getSomaXYZ, obj.neurons,...
                'UniformOutput', false));
            xyz = xyz(:,3);     
        end
    end

    methods (Access = private)
        function createAnalysisTable(obj, DisplayName)
            hasAnalysis = obj.hasAnalysis(DisplayName);
            [~, ind] = find(~hasAnalysis);
            for i = 1:numel(ind)
                obj.neurons(ind(i)).addAnalysis();
            end
            T = arrayfun(@(x) structfun(x.analysis(DisplayName).data,... 
                'AsArray', true), obj.neurons, 'UniformOutput', false);
            obj.analyses(DisplayName) = vertcat(T{:});
        end

        function tf = hasAnalysis(obj, DisplayName)
            % HASANALYSIS  Returns logical array 
            tf = arrayfun(@(x) isKey(x.analysis,DisplayName), neurons);
        end
    end
end