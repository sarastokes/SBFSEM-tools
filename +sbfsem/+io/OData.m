classdef OData < handle
    % ODATA
    %
    % Description:
    %   Parent class for all OData query subclasses, handles misc
    %   standalone OData queries
    %
    % Constructor:
    %   obj = sbfsem.io.OData(source)
    % Inputs:
    %   source      Volume name or abbreviation
    %
    % Protected properties:
    %   source      Full volume name (char)
    %   baseURL     Service root (char)
    %   webOpt      OData-specific weboptions
    %
    % History:
    %   17Dec2017 - SSP
    %   5Mar2018 - SSP - Updated for new JSON decoder
    % ---------------------------------------------------------------------

	properties (Access = protected)
		source
		baseURL
        webOpt
	end

	methods
		function obj = OData(source)
            % ODATA  Constructor
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), '/', 'OData/'];
            obj.webOpt = getODataOptions();
		end
	end

	methods (Access = protected)
        function Locs = fetchLocationData(obj, ID)
            % FETCHLOCATIONDATA  Returns locations for neuron
            % Inputs:
            %   ID          Structure ID number

            locationURL = getODataURL(ID, obj.source, 'location');
            importedData = readOData(locationURL);
            value = cat(1, importedData.value{:});
            if ~isempty(importedData.value)
                Locs = obj.processLocationData(value);
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
            value = cat(1, importedData.value{:});
            if ~isempty(importedData.value)
                LocLinks = zeros(size(value, 1), 3);
                LocLinks(:, 1) = repmat(ID, [size(importedData, 1), 1]);
                LocLinks(:, 2) = vertcat(value.A);
                LocLinks(:, 3) = vertcat(value.B);
            else
                LocLinks = [];
            end
        end		
	end

	methods
		function data = annotationsBySection(obj, sections)
            % ANNOTATIONSBYSECTION
            % Input:
            %   sections        range of Z sections (vector)
            % TODO: expand links t/f option
			str = ['/Locations?$filter=Z le ' num2str(max(sections)),...
				' and Z ge ', num2str(min(sections)),...
				' and TypeCode eq 1',...
                '&$select=ID,ParentID,X,Y,Z,Radius'];            

			data = webread([getServiceRoot(obj.source), str], obj.webOpt);
		end

		function data = getLinkedIDs(obj, ID)
            % GETLINKEDIDS  From ID, get other linked location IDs
            % Inputs:
            %   ID          The location ID
            %   vitread     Direction (t/f), empty for both
            
            str = [getServiceRoot(obj.source),...
                'Locations(' num2str(ID) ')',...
                '&$expand=LocationLinksA'];
            
            data = webread(str, obj.webOpt);
        end

        function data = getLastAnnotations(obj, ID, numAnnotations)
            % GETLASTANNOTATIONS
            % Input:
            %   ID                  StructureID
            % Optional input:
            %   numAnnotations      Number to return (default = 1)

            if nargin < 3
                numAnnotations = 1;
            end
            
            str = [getServiceRoot(obj.source),...
                'Structures(' num2str(ID) ')/Locations',...
                '?$orderby=LastModified desc ',...
                '&$top=', num2str(numAnnotations)];
            data = webread(str, obj.webOpt);
            data = cat(1, data.value{:});
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