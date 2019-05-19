classdef NeuronJSON < sbfsem.core.NeuronAPI
	% NEURONJSON
	%
	% Description:
	%	Instantiates a Neuron object from a JSON file
	%
	% Constructor:
	% 	obj = NeuronJSON(jsonPath)
	% 
	% History:
	%	21Aug2018 - SSP
    %   25Nov2018 - SSP - Removed webread dependencies, works offline now
	% ---------------------------------------------------------------------

	properties
		fPath 		% JSON file path
	end

	methods
		function obj = NeuronJSON(jsonPath)
            % NEURONJSON  Constructor
            if nargin < 1
                [fileName, filePath] = uigetfile('.json', 'Pick a JSON file');
                jsonPath = [filePath, fileName];
            end
            
			[~, fName, ext] = fileparts(jsonPath);
			assert(strcmp(ext, '.json'), 'Input must be a JSON file!');
            
            ID = str2double(fName(2:end));            
            source = validateSource(fName(1));
            obj@sbfsem.core.NeuronAPI(ID, source);
            
			obj.fPath = jsonPath;

			obj.parseJSON(obj.fPath);
        end
        
        function update(~)
            % UPDATE  Overwrite, this function is only useful for databases
        end
	end

	methods (Access = private)
		function parseJSON(obj, jsonFile)
			% Load JSON as a struct
			S = loadjson(jsonFile);

			assert(obj.ID == S.ID,... 
				'ID of imported JSON file does not match title ID');
			assert(strcmp(obj.source, S.source), 'Volume names do not match');

			% The easy stuff
			obj.viking = S.viking;
			obj.volumeScale = S.volumeScale;
			obj.omittedIDs = S.omittedIDs;
			obj.lastModified = S.lastModified;

			% Convert to tables
			obj.nodes = struct2table(vertcat(S.nodes{:}{:}));
			obj.edges = struct2table(vertcat(S.edges{:}{:}));
			if ~isempty(S.geometries)
				obj.geometries = struct2table(vertcat(S.geometries{:}{:}));
			end
			if ~isempty(S.synapses)
                try
    				obj.synapses = struct2table(vertcat(S.synapses{:}{:}));
                catch
                    obj.synapses = [];
                end
			end

			% Convert the enumerations
			obj.transform = sbfsem.core.Transforms.fromStr(S.transform);
            if ~isempty(obj.synapses)
                obj.synapses.LocalName = arrayfun(@(x) sbfsem.core.StructureTypes(x), obj.synapses.LocalName);
            end
            
			% Convert the model... ? For now, just rebuild it.
			if ~isempty(S.model)
				obj.build();
			end
		end
	end
end