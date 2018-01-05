classdef NeuronGroup < handle
% NEURONGROUP  
%
% Description:
%   A group of neuron objects
%
% Constructor:
%   obj = NEURONGROUP(neurons, source);
% where neurons can be Neuron objects or an array of ID numbers
%
% Properties:
%   neurons             NeuronList holding the Neuron objects
%   IDs                 Neuron ID numbers
%   analyses            NeuronAnalysis results
%   source              Volume name
%   description         Info on the NeuronGroup
%   plotColor           Color the neuron group somas are plotted with
%
% Methods:
%   n = obj.numel           Returns number of neurons in list
%   obj.add(neuron)         Append a Neuron object
%   obj.describe(str)       Add a description to the NeuronGroup
%   x = somaDiameter(obj)   Get soma diameters
%   obj.somaPlot(varargin)  Plot soma mosaic
%   obj.setPlotColor(rgb)   Set plot color for mosaics
%
%
% History:
%   30Nov2017 - SSP
%   4Jan2018 - SSP - Improved NeuronList implementation
%
% -------------------------------------------------------------------------
   
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
            if isa(neurons, 'sbfsem.core.NeuronList')
                obj.neurons = neurons;
            else
                obj.neurons = sbfsem.core.NeuronList(neurons, source);
            end
            obj.IDs = obj.neurons.getIDs();
        end
        
        function n = numel(obj)
            % NUMEL  Number of neurons in group
            n = obj.neurons.length();
        end

        function add(obj, neuron)
            % ADD  Append more neurons
            % Input:
            %   neuron      ID numbers or Neurons
            % TODO: consolidate constructor and add
            if isa(neuron, 'Neuron')
                for i = 1:numel(neuron)
                    obj.IDs = cat(1, obj.IDs, neuron);
                    for j = 1:numel(obj.IDs)
                        obj.neurons = cat(1, obj.neurons,...
                            Neuron(obj.IDs(j), obj.source));
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
            
            somaSizes = [];
            x = sbfsem.core.NeuronListIterator(obj);
            while x.hasNext
                elt = x.next();
                somaSizes = cat(1, somaSizes, elt.getSomaSize(true));
            end
            
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
            addParameter(ip, 'validateSizes', false, @islogical);
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'Color', obj.plotColor, @(x) isvector(x) || isvector(x));
            addParameter(ip, 'LineWidth', 1, @isnumeric);
            addParameter(ip, 'addLabel', false, @islogical);
            parse(ip, varargin{:});
            validateSizes = ip.Results.validateSizes;

            if isempty(ip.Results.ax)
                fh = sbfsem.ui.FigureView(1);
                ax = fh.ax;
            else
                ax = ip.Results.ax;
            end

            [somaSizes, validIDs] = obj.somaDiameter(validateSizes);
            
            xyz = [];
            x = sbfsem.core.NeuronListIterator(obj);
            while x.hasNext
                elt = x.next();
                if ismember(elt.ID, validIDs)
                    xyz = cat(1, xyz, elt.getSomaXYZ);
                end
            end
            x.reset();

            for i = 1:size(xyz, 1)
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

        function [ind, dst] = nearestNeighbor(obj, k)
            if nargin < 2
                k = 3;
            end
            % [somaSizes, validIDs] = obj.somaDiameter(false);
            % validNeurons = [];
            % for i = 1:numel(obj.neurons)
            %     if ismember(obj.neurons(i).ID, validIDs)
            %         validNeurons = cat(1, validNeurons, obj.neurons(i));
            %     end
            % end
            xyz = cell2mat(arrayfun(@(x) x.getSomaXYZ, obj.neurons,...
                'UniformOutput', false));
            xyz = xyz(:,1:2);
            [ind, dst] = knnsearch(xyz, xyz, 'K', k);

            fh = sbfsem.ui.FigureView(1);
            set(fh.figureHandle, 'Name', 'knnsearch result');
            barh(fh.ax, dst(:,2:k), 'stacked');
            %set(fh.ax, 'YTickLabel', lbl, 'Box', 'off');
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

        function doAnalysis(obj, DisplayName)
            obj.createAnalysisTable(DisplayName);
        end
    end

    methods (Access = private)
        function createAnalysisTable(obj, DisplayName)
            hasAnalysis = obj.hasAnalysis(DisplayName);
            [~, ind] = find(~hasAnalysis);
            for i = 1:numel(ind)
                obj.neurons(ind(i)).addAnalysis(analysis(obj.neurons(i)));
            end
            T = arrayfun(@(x) structfun(x.analysis(DisplayName).data,... 
                'AsArray', true), obj.neurons, 'UniformOutput', false);
            obj.analyses(DisplayName) = vertcat(T{:});
        end

        function tf = hasAnalysis(obj, DisplayName)
            % HASANALYSIS  Returns logical array 
            tf = arrayfun(@(x) isKey(x.analysis,DisplayName), obj.neurons);
        end
    end
end