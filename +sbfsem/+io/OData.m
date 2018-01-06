classdef OData < handle

	properties (Access = protected)
		source
		baseURL
	end

	methods
		function obj = OData(source)
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), '/', 'OData/'];
		end
	end

	methods (Access = protected)
        function Locs = fetchLocationData(obj, ID)
            % FETCHLOCATIONDATA  Returns locations for neuron
            % Inputs:
            %   ID          Structure ID number

            locationURL = getODataURL(ID, obj.source, 'location');
            importedData = readOData(locationURL);
            if ~isempty(importedData.value)
                Locs = obj.processLocationData(importedData.value);
            else
                Locs = [];
                % This is important to track bc throws errors in VikingPlot
                fprintf('No locations for s%u\n', obj.ID);
            end
        end
        
        function LocLinks = fetchLinkData(obj, ID)
            % FETCHLINKDATA  Returns edges for given ID 
            % Inputs:
            %   ID          Structure ID number
            
            linkURL = getODataURL(ID, obj.source, 'link');
            importedData = readOData(linkURL);
            if ~isempty(importedData.value)
                LocLinks = zeros(size(importedData.value, 1), 3);
                LocLinks(:, 1) = repmat(ID, [size(importedData, 1), 1]);
                LocLinks(:, 2) = vertcat(importedData.value.A);
                LocLinks(:, 3) = vertcat(importedData.value.B);
            else
                LocLinks = [];
            end
        end		
	end

	methods
		function annotationsBySection(obj, sections)

			str = ['/Locations?$filter=Z le ' num2str(max(sections)),...
				' and Z ge ', num2str(min(sections)),...
				' and TypeCode eq 1'];

			data = webread([getServiceRoot(obj.source), str,...
				'&$select=ID,ParentID,X,Y,Z,Radius'], weboptions);
		end

		function structureByLabel(obj, str)
			
		end
	end

	methods (Static = true, Access = protected)
		function N = getEdgeHeaders()
	        N = {'ID', 'A', 'B'};
	    end

	    function N = getNodeHeaders()
	        N = {'ID', 'ParentID', 'VolumeX',...
            'VolumeY', 'Z', 'Radius', 'X', 'Y',...
            'OffEdge', 'Terminal', 'Geometry'};
        end

        function Locs = processLocationData(value)
            % PROCESSLOCATIONDATA  Organize according to headers
            % ID, ParentID, VolumeX, VolumeY, Z, Radius, X, Y, OffEdge,
            % Terminal, Geometry
            Locs = zeros(size(value, 1), 11);
            Locs(:, 1) = vertcat(value.ID);
            Locs(:, 2) = vertcat(value.ParentID);
            Locs(:, 3) = vertcat(value.VolumeX);
            Locs(:, 4) = vertcat(value.VolumeY);
            Locs(:, 5) = vertcat(value.Z);
            Locs(:, 6) = vertcat(value.Radius);
            Locs(:, 7) = vertcat(value.X);
            Locs(:, 8) = vertcat(value.Y);
            Locs(:, 9) = vertcat(value.OffEdge);
            Locs(:, 10) = vertcat(value.Terminal);
            Locs(:, 11) = vertcat(value.TypeCode);
        end
	end
end