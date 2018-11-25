classdef JSON < handle
    % JSON
    %
    % Description:
    %   Handles conversion of SBFSEM-tools data to JSON files.
    %
    % Constructor:
    %   obj = sbfsem.io.JSON(source, fPath);
    %
    % Input:
    %   source      Volume name or abbreviation
    %   fPath       File path to save JSON files (optional, if not 
    %               specified, opens a user interface to choose directory)
    % ---------------------------------------------------------------------
    
    properties (Access = private)
        fPath
        source
        hasMetadata
    end
    
    methods
        function obj = JSON(source, fPath)
            % JSON Constructor
            % Input:
            %   fPath   Directory to save JSON data
            
            if nargin == 1 || ~isfolder(fPath)
                obj.fPath = uigetdir();
            else
                obj.fPath = fPath;
            end
            cd(obj.fPath);
            
            obj.source = validateSource(source);
        end
        
        function neuron = import(obj, jsonPath)
            % IMPORT
            if nargin == 0
                jsonPath = '';
            end
            if ~ismember(filesep, jsonPath)
                jsonPath = [obj.fPath, filesep, jsonPath];
            end
            neuron = NeuronJSON(jsonPath);
        end
            
        function str = export(obj, neuron)
            % EXPORT  Exports a neuron to filePath
            % 
            % Input:
            %   neuron      Neuron object
            % -------------------------------------------------------------
            
            assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input a Neuron!'); 
            
            fName = sprintf('%s%u.json',... 
                getVolumeAbbrev(obj.source), neuron.ID);
            
            % Ensure synapses and geometries are present, if existing
            if isempty(neuron.synapses)
                neuron.getSynapses();
            end
            
            if isempty(neuron.geometries)
                neuron.getGeometries();
            end
            
            % Matlab doesn't like converting objects to structures
            warning('off', 'MATLAB:structOnObject');
            % First convert the model object, if necessary
            if ~isempty(neuron.model)
                neuron.model = struct(neuron.model);
            end
            % Next convert the entire Neuron object to a structure
            S = struct(neuron);
            
            S = obj.prep(S);
            
            str = savejson('', S, [obj.fPath, filesep, fName]);
        end
    end
    
    methods (Static)
        function S = prep(S)
            % PREP  Ensure structure is JSON compliant
            
            % Remove unecessary, transient/dependent properties
            S = rmfield(S, {'ODataClient', 'GeometryClient', 'SynapseClient'});
            S = rmfield(S, {'somaRow', 'offEdges', 'includeSynapses'});

            S.nodes = table2struct(S.nodes);
            S.edges = table2struct(S.edges);
            
            if ~isempty(S.synapses)
                S.synapses.LocalName = arrayfun(@char, S.synapses.LocalName,...
                    'UniformOutput', false);
            end
            S.synapses = table2struct(S.synapses);
            % Enumeration to string
            S.transform = char(S.transform);
            
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