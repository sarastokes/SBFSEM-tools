classdef NeuronJSON < NeuronAPI
	% NEURONJSON
	%
	% Description:
	%	Instantiates a Neuron object from a JSON file
	%
	% Constructor:
	% 	obj = NeuronJSON()
	% 
	% History:
	%	21Aug2018 - SSP
	% ------------------------------------------------------------------

	properties
		fPath 		% JSON file path
	end

	methods
		function obj = NeuronJSON(fPath)
			[fPath, fName, ext] = fileparts(fPath);
			assert(strcmp(ext, '.json'), 'Input path to a JSON file!');
			obj.fPath = fPath;

			obj.source = validateSource(fName(1));
			obj.ID = num2str(fName(2:end));

			obj.parseJSON();
        end
	end

	methods (Access=private)
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
			obj.nodes = struct2table(vertcat(obj.nodes{:}{:}));
			obj.edges = struct2table(vertcat(obj.edges{:}{:}));
			if ~isempty(S.geometries)
				obj.geometries = struct2table(vertcat(S.geometries{:}{:}));
			end
			if ~isempty(S.synapses)
				obj.synapses = struct2table(vertcat(S.synapses{:}{:}));
			end

			% Convert the enumerations
			obj.transform = sbfsem.core.Transforms.fromStr(S.transform);
			obj.synapses.LocalName = vertcat(arrayfun(...
				@(x) sbfsem.core.StructureTypes(x.LocalName),...
				obj.synapses));

			% Convert the model... ? For now, just rebuild it.
			if ~isempty(S.model)
				obj.build();
			end
		end
	end
end