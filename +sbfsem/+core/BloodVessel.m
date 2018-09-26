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
% -------------------------------------------------------------------------

	properties
		ODataClient
		GeometryClient
	end

	methods
		function obj = BloodVessel(ID, source, transform)
			obj@sbfsem.core.StructureAPI();

			validateattributes(ID, {'numeric'}, {'numel', 1});
			obj.ID = ID;
			obj.source = validateSource(source);

            if nargin < 3
                obj.transform = sbfsem.core.Transforms.Viking;
            else
                obj.transform = sbfsem.core.Transforms.fromStr(transform);
            end

            % XYZ volume dimensions in nm/pix, nm/pix, nm/sections
            obj.volumeScale = getODataScale(obj.source);

        	% Instantiate OData clients
            obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);
            obj.GeometryClient = [];

            % Fetch neuron OData and parse
            obj.pull();

            % Track when the Neuron object was created
            obj.lastModified = datestr(now);
		end

        function update(obj)
            % UPDATE  Updates existing OData
            % If you haven't imported synapses the update will skip them
            fprintf('NEURON: Updating OData for c%u\n', obj.ID);
            obj.pull();
            obj.lastModified = datestr(now);
        end
	end

	% Closed curve methods
	methods
        function getGeometries(obj)
            % GETGEOMETRIES  Import ClosedCurve-related OData
            if isempty(obj.GeometryClient)
                obj.GeometryClient = sbfsem.io.GeometryOData(obj.ID, obj.source);
            end
            obj.geometries = obj.GeometryClient.pull();
        end

        function checkGeometries(obj)
            % CHECKGEOMETRIES   Try to import geometries, if missing
            if isempty(obj.geometries)
                obj.getGeometries();
            end
        end
	end

	methods (Access = private)
		function pull(obj)
			% PULL  Fetch and parse OData

            % Get the relevant data with OData queries
            [obj.viking, obj.nodes, obj.edges] = obj.ODataClient.pull();
            % XY transform and then convert data to microns
            obj.nodes = obj.setXYZum(obj.nodes);

            if nnz(obj.nodes.Geometry == 6)
                obj.getGeometries();
                fprintf('     %u closed curve geometries\n',...
                    height(obj.geometries));
            end

            % Search for omitted nodes by location ID and section number
            obj.omittedIDs = omitLocations(obj.ID, obj.source);
            omittedSections = omitSections(obj.source);
            if ~isempty(omittedSections)
                for i = 1:numel(omittedSections)
                    row = obj.nodes.Z == omittedSections(i);
                    obj.omittedIDs = [obj.omittedIDs; obj.nodes(row,:).ID];
                end
            end
		end

        function nodes = setXYZum(obj, nodes)
            % SETXYZUM  Convert Viking pixels to microns
            if nnz(nodes.X) + nnz(nodes.Y) > 2
                nodes = estimateSynapseXY(obj, nodes);
            end
            
            % Apply transforms to NeitzInferiorMonkey
            if obj.transform == sbfsem.core.Transforms.SBFSEMTools
                xyDir = [fileparts(mfilename('fullpath')), '\data'];
                xydata = dlmread([xyDir,...
                    '\XY_OFFSET_NEITZINFERIORMONKEY.txt']);
                volX = nodes.X + xydata(nodes.Z,2);
                volY = nodes.Y + xydata(nodes.Z,3);
            else
                volX = nodes.VolumeX;
                volY = nodes.VolumeY;
            end

            % Create an XYZ in microns column
            nodes.XYZum = zeros(height(nodes), 3);
            % TODO: There's an assumption about the units in here...
            nodes.XYZum = bsxfun(@times,...
                [volX, volY, nodes.Z],...
                (obj.volumeScale./1e3));
            % Create a column for radius in microns
            nodes.Rum = nodes.Radius * obj.volumeScale(1)./1000;
        end
	end
end