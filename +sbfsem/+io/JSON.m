classdef JSON < handle
    % JSON
    %
    % Description:
    %   Handles conversion of SBFSEM-tools data to JSON files.
    %
    % ---------------------------------------------------------------------
    
    properties (Access = private)
        fPath
        hasMetadata       
    end
    
    methods
        function obj = JSON(fPath)
            % JSON Constructor
            % Input:
            %   fPath   Directory to save JSON data
            
            if nargin == 0 || ~isdir(fPath)
                obj.fPath = uigetdir();
            else
                obj.fPath = fPath;
            end
        end
        
        function export(obj, neuron)
            % EXPORT
            assert(isa(neuron, 'Neuron'), 'Input a Neuron!'); 
            
            % Ensure synapses and geometries are present, if existing
            if isempty(neuron.synapses)
                neuron.getSynapses();
            end
            
            if isempty(neuron.geometries)
                neuron.getGeometries();
            end
            
            % Matlab doesn't like converting objects to structures
            warning('off', 'MATLAB:structOnObject');
            S = struct(neuron);
            
            S = obj.prep(S);
        end
    end
    
    methods (Static)
        function S = prep(S)
            % PREP  Ensure structure is JSON compliant
            
            % Remove unecessary, transient/dependent properties
            S = rmfield(S, {'ODataClient', 'GeometryClient', 'SynapseClient'});
            S = rmfield(S, {'somaRow', 'offEdges'});
            S = rmfield(S, 'includeSynapses');
            
            S.volumeScale = struct(...
                'value', S.volumeScale,...
                'unit', {'nm per pixel', 'nm per pixel', 'nm per section'});
            
            S.nodes = table2struct(S.nodes);
            S.edges = table2struct(S.edges);
            
            if ~isempty(S.synapses)
                S.synapses.LocalName = arrayfun(@char, S.synapses.LocalName);
            end
            
            if ~isempty(S.analysis)
                % Create a struct for storing analyses
                SA = struct();
                % Convert each NeuronAnalysis into a struct
                keys = S.analysis.keys;
                for i = 1:numel(keys)
                    analysis = S.analysis(keys{i});
                    analysis = struct(analysis);
                    SA.(keys{i}) = analysis;
                end
                % Save the struct of NeuronAnalysis structs
                S.analysis = SA;
            else
                S = rmfield(S, 'analysis');
            end
        end
    end
end