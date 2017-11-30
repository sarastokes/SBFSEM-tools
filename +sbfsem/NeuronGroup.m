classdef NeuronGroup < handle
    
    properties
        neurons
        IDs
    end
    
    methods
        function obj = NeuronGroup(neurons, source)
            switch class(neurons)
                case 'double'
                    obj.IDs = neurons;
                    obj.neurons = [];
                    for i = 1:numel(obj.IDs)
                        obj.neurons = cat(1, obj.neurons,...
                            sbfsem.Neuron(obj.IDs(i), source));
                    end
                case 'sbfsem.Neuron'
                    obj.IDs = arrayfun(@(x) x.ID, neurons);
                    obj.neurons = neurons;
            end
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

        function fh = somaPlot(obj)
            fh = sbfsem.ui.FigureView(1);

            [somaSizes, validIDs] = obj.somaDiameter(true);

            validNeurons = [];
            for i = 1:numel(obj.neurons)
                if ismember(obj.neurons(i).ID, validIDs)
                    validNeurons = cat(1, validNeurons, obj.neurons(i));
                end
            end
            xyz = cell2mat(arrayfun(@(x) x.getSomaXYZ, validNeurons,...
                'UniformOutput', false));
        end

        function arborArea(obj, somaIndex)
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
end