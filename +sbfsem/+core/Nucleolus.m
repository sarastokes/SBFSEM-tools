classdef Nucleolus < sbfsem.core.StructureAPI
    % NUCLEOLUS
    %
    % Description:
    %   Class representing Nucleolus child structure
    %
    % Constructor:
    %   obj = sbfsem.core.Nucleolus(ParentID, source, transform);
    %
    % Inputs:
    %   ParentID        Parent Structure ID number
    %   source          Volume name or abbreviation
    % Optional inputs:
    %   Transform       sbfsem.core.Transforms (default = Viking)
    %
    % See also:
    %   NEURON, SBFSEM.CORE.STRUCTUREAPI
    %
    % History:
    %   1Nov2018 - SSP
    % ---------------------------------------------------------------------

	properties (SetAccess = private)
		ParentID
    end
    
    properties (Hidden, Transient = true)
        GeometryClient
    end

	properties (Hidden, Constant = true)
		STRUCTURE = 'Nucleolus';
	end

	methods
		function obj = Nucleolus(parentID, source, transform)
            % Instantiate with the ID of Nucleolus child structure
			ID = sbfsem.core.Nucleolus.getIDByParent(parentID, source);
			obj@sbfsem.core.StructureAPI(ID, source);
            
			obj.ParentID = parentID;

			if nargin < 3
				obj.transform = sbfsem.core.Transforms.Viking;
			else
				obj.transform = sbfsem.core.Transforms.fromStr(transform);
			end

			% Instantiate OData clients
			obj.GeometryClient = [];

			% Fetch neuron OData and parse
			obj.pull();
		end
	end

	methods (Static)
		function ID = getIDByParent(parentID, source)
            % GETIDBYPARENT  Query ParentID for Nucleolus child structures
            source = validateSource(source);
			data = readOData([getServiceRoot(source), 'Structures',...
				'?$filter=TypeID eq 245 and ParentID eq ', num2str(parentID),...
				'&$select=ID']);
			if isempty(data.value)
                error('SBFSEM:CORE:NUCLEOLUS:InvalidID',...	
                	'ParentID did not contain Nucleolus');
				
            elseif numel(data.value{:}) > 1
                error('SBFSEM:CORE:NUCLEOLUS:NotYetImplemented',...
                    'Multiple nucleolus child structures returned');
            else
                ID = data.value{:}.ID;
			end
		end
	end
end