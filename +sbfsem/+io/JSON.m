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
    
    properties (Constant = true, Access = private)
        NEURON_NAME = '%s%u.json';
        METADATA_NAME = '%s_metadata.json';
    end

    methods
        function obj = JSON(source, fPath)
            % JSON Constructor
            % Input:
            %   fPath   Directory to save JSON data
            
            if nargin == 0 || ~isdir(fPath)
                obj.fPath = uigetdir();
            else
                obj.fPath = fPath;
            end
            cd(obj.fPath);
            
            obj.source = validateSource(source);
            
            obj.hasMetadata = obj.findMetadata;
            if ~obj.hasMetadata
                fprintf('No metadata found for %s\n', obj.source);
                value = questdlg(...
                    'No volume metadata found. Create one?',...
                    'Volume Metadata Dialog', 'Yes', 'No', 'Yes');
                if ~isempty(value)
                    switch value
                        case 'Yes'
                            obj.saveMetadata();
                        case 'No'
                            return;
                    end
                end
            end
        end
            
        function export(obj, neuron)
            % EXPORT  Exports a neuron to filePath
            % 
            % Input:
            %   neuron      Neuron object
            % -------------------------------------------------------------
            
            assert(isa(neuron, 'Neuron'), 'Input a Neuron!'); 
            
            fName = sprintf('%s%u.json',... 
                getVolumeAbbrev(obj.source), num2str(neuron.ID), '.json');
            
            hasNeuron = obj.findNeuron(obj, ID);
            
            if hasNeuron
                value = questdlg('Overwrite existing file?',...
                    'Overwrite dialog', 'Yes', 'No', 'Yes');
                if ~isempty(value) || strcmp(value, 'No')
                    return;
                end
            end
            
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
            
            obj.findNeuron(fName);
            
            savejson('', S, [obj.fPath, filesep, fName]);
        end
    end
    
    methods (Access = private)        
        function tf = findNeuron(obj, ID)
            % FINDNEURON
            str = sprintf(obj.NEURON_NAME,... 
                getVolumeAbbrev(obj.source), ID);
            cd(obj.fPath);
            x = cellstr(ls(str));
            tf = ~isempty(x);
        end
      
        function tf = findMetadata(obj)
            % FINDMETADATA
            
            str = sprintf(obj.METADATA_NAME, obj.source);
            cd(obj.fPath)
            x = cellstr(ls(str));
            tf = ~isempty(x);           
        end
        
        function saveMetadata(obj)
            % SAVEMETADATA
            
            S = struct(...
                'VolumeName', obj.source,... 
                'DateCreated', datestr(now));       
            dataDir = [fileparts(mfilename('fullpath')), '\data'];
        end
    end
    
    methods (Static)
        function S = prep(S)
            % PREP  Ensure structure is JSON compliant
            
            % Remove unecessary, transient/dependent properties
            S = rmfield(S, {'ODataClient', 'GeometryClient', 'SynapseClient'});
            S = rmfield(S, {'somaRow', 'offEdges'});
            S = rmfield(S, {'includeSynapses', 'USETRANSFORM'});

            S.nodes = table2struct(S.nodes);
            S.edges = table2struct(S.edges);
            
            if ~isempty(S.synapses)
                S.synapses.LocalName = arrayfun(@char, S.synapses.LocalName,...
                    'UniformOutput', false);
            end
            S.synapses = table2struct(S.synapses);
            
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