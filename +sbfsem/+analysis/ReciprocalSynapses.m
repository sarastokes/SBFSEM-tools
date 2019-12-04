classdef ReciprocalSynapses < sbfsem.analysis.NeuronAnalysis
% RECIPROCALSYNAPSES
%
% Description:
%   Get potential reciprocal synapses within a given search radius
%
% Syntax:
%   obj = ReciprocalSynapses(neuron, searchRadius);
%
% Inputs:
%   neuron              sbfsem.core.StructureAPI subclass
% Optional inputs:
%   searchRadius        in microns, default = 0.5 um
%
% References:
%   The default 500 nm search radius is from:
%       Tsukamoto & Oni (2016) ON bipolar cells in macaque retina: 
%       Type-specific synaptic connectivity with special reference to OFF 
%       counterparts. Frontiers in Neuroanatomy, 10:104
%
% See also:
%   sbfsem.core.NeuronAnalysis, fastEuclid3d
%
% History:
%   13Nov2018 - SSP - Ported from python reciprocal synapse function 
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        searchRadius
        dstData
        neuron
        neuronType
        reciprocalIDs
        preSynData
        postSynData
    end

    methods
        function obj = ReciprocalSynapses(neuron, searchRadius)
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            obj.neuron = neuron;

            if nargin < 2
                obj.searchRadius = 0.5;  % microns
            else
                obj.searchRadius = searchRadius;
            end

            obj.neuron.checkSynapses();
            obj.assignType();
            fprintf('c%u assigned type: %s\n', obj.neuron.ID, obj.neuronType);
            
            obj.fetchData();
            obj.doAnalysis();
        end

        function doAnalysis(obj, searchRadius)
            % DOANALYSIS
            %
            % Inputs:
            %   searchRadius    in nanometers (default = 500nm)
            
            if numel(obj.reciprocalIDs) == 0
                disp('No reciprocal IDs found!'); return;
            end

            if nargin == 2
                obj.searchRadius = searchRadius;
            end
            fprintf('c%u - Analyzing with a %.3g micron search radius\n',...
                obj.neuron.ID, obj.searchRadius);
            
            % Remove NaNs and return as arrays
            [preData, postData] = obj.rmUnlinked(false);
            preNeurons = preData(:, 1); preSynapses = preData(:, 2); 
            postNeurons = postData(:, 1); postSynapses = postData(:, 2); 
            
            dataTable = [];
             fprintf('Analyzing %u neurons: ', numel(obj.reciprocalIDs));
            for i = 1:numel(obj.reciprocalIDs)
                fprintf('%u, ', obj.reciprocalIDs(i));
                preIDs = preSynapses(preNeurons == obj.reciprocalIDs(i));
                postIDs = postSynapses(postNeurons == obj.reciprocalIDs(i));
                for j = 1:numel(preIDs)
                    preXYZ = obj.neuron.nodes{obj.neuron.nodes.ParentID == preIDs(j), 'XYZum'};
                    for k = 1:numel(postIDs)
                        postXYZ = obj.neuron.nodes{obj.neuron.nodes.ParentID == postIDs(k), 'XYZum'};
                    end
                    D = pdist2(preXYZ, postXYZ);
                    dataTable = cat(1, dataTable,...
                        [obj.reciprocalIDs(i), preIDs(j), postIDs(k), min(min(D))]);
                end 
            end
            obj.data = array2table(dataTable);
            obj.data.Properties.VariableNames = {'NeuronID', 'PreID', 'PostID', 'Distance'};
            obj.data = sortrows(obj.data, 'Distance');
            fprintf('\n');
        end

        function plot(obj)
            % PLOT  Visualize potential reciprocal synapses
            if isempty(obj.data)
                warning('No analysis data to plot!');
                return;
            end
        end

        function [preData, postData] = rmUnlinked(obj, returnTable)
            % RMUNLINKED  Remove NaNs from pre and post synaptic data tables
            if nargin < 2
                returnTable = true;
            else
                assert(islogical(returnTable), 'returnTable must be true/false');
            end

            fprintf('%u of %u pre-synaptic neurons are unannotated\n',...
                nnz(isnan(obj.preSynData.preNeurons)), height(obj.preSynData));
            fprintf('%u of %u post-synaptic neurons are unannotated\n',... 
                nnz(isnan(obj.postSynData.postNeurons)), height(obj.postSynData));
            preData = obj.preSynData{~isnan(obj.preSynData.preNeurons), :};
            postData = obj.postSynData{~isnan(obj.postSynData.postNeurons), :};

            if returnTable
                preData = array2table(preData,...
                    'VariableNames', {'preNeurons', 'preSynapses'});
                postData = array2table(postData,...
                    'VariableNames', {'postNeurons', 'postSynapses'});
            end
        end
    end

    methods (Access = private)
        function fetchData(obj)
            % FETCHDATA  Query database for linked neurons
            switch obj.neuronType
                case 'bipolar'
                    preName = 'ConvPost'; postName = 'RibbonPre';
                case 'amacrine'
                    preName = 'RibbonPost'; postName = 'ConvPre';
            end

            % Get bipolar cell ribbon output and amacrine cell feedback
            disp('Fetching post-synaptic neurons...');
            [postNeurons, postSynapses, ~] = getLinkedNeurons(obj.neuron, postName);
            disp('Fetching pre-synaptic neurons...')
            [preNeurons, preSynapses, ~] = getLinkedNeurons(obj.neuron, preName);

            obj.preSynData = table(preNeurons, preSynapses);
            obj.postSynData = table(postNeurons, postSynapses);
            
            obj.reciprocalIDs = intersect(preNeurons, postNeurons);
            if numel(obj.reciprocalIDs) == 0
                disp('No reciprocal IDs found!'); return;
            end
        end

        function assignType(obj)
            % ASSIGNTYPE  Guess at the neuron's subtype
            if obj.neuron.getSynapseN('RibbonPre') > obj.neuron.getSynapseN('RibbonPost')
                obj.neuronType = 'bipolar';
            elseif obj.neuron.getSynapseN('BipConvPre') > 0
                obj.neuronType = 'bipolar';
            elseif obj.neuron.getSynapseN('ConvPre') > 0
                obj.neuronType = 'amacrine';
            end
        end
    end
end