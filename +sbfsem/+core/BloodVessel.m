classdef BloodVessel < sbfsem.core.StructureAPI
% BLOODVESSEL
%
% Description:
%	A class representing Blood Vessel annotations in Viking
%
% Constructor:
%	obj = sbfsem.core.BloodVessel(ID, source, transform)
%
% History:
%	25Sept2018 - SSP
%	1Oct2018 - SSP - Added vessel adjacencies
% -------------------------------------------------------------------------

	properties (SetAccess = private)
		vesselAdjacencies = [];
	end

	properties (Dependent = true, Hidden = true)
		hasAdjacencies
	end
	
	properties (Constant = true, Hidden = true)
		STRUCTURE = 'Blood Vessel';
	end

	methods
		function obj = BloodVessel(ID, source, transform)
			obj@sbfsem.core.StructureAPI(ID, source);

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

		function hasAdjacencies = get.hasAdjacencies(obj)
			hasAdjacencies = ~isempty(obj.vesselAdjacencies);
		end

		function getAdjacencies(obj)
			data = readOData(getODataURL(obj.ID, obj.source, 'child'));
			data = cat(1, data.value{:});

			childIDs = [];
			obj.vesselAdjacencies = [];

			for i = 1:numel(data)
				childIDs = cat(1, childIDs, data(i).ID);
				obj.vesselAdjacencies = cat(1, obj.vesselAdjacencies,...
					sbfsem.core.VesselAdacency(childIDs(end), obj.source));
			end
		end

        function render(obj, varargin)
        	render@sbfsem.core.StructureAPI(obj, varargin{:});

        	if obj.hasAdjacencies
        		for i = 1:numel(obj.vesselAdjacencies)
        			obj.vesselAdjacencies(i).render('ax', gca,...
        				'FaceColor', [0.7, 0.7, 0.7])
        		end
        	end
        end
	end
end