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

	properties (Access = public)
		source
		baseURL
        webOpt
	end

	methods
		function obj = OData(source)
            % ODATA  Constructor
            if nargin == 0
                error('SBFSEM:OData:InsufficientInput',...
                    'Must provide a volume name or abbreviation');
            end
			obj.source = validateSource(source);
			obj.baseURL = [getServerName(), 'OData/'];
            obj.webOpt = getODataOptions();
        end
        
        function str = getURL(obj)
            % GETURL  Returns the base URL
            str = obj.baseURL;
        end
    end

    methods
        function N = countCellsInVolume(obj)
            url = [obj.baseURL, 'Structures?$filter=TypeID eq 1 &$count=true'];
            data = webread(url, obj.webOpt);
            N = data.x_odata_count;
        end

        function N = countLocationsInVolume(obj)
        end
    end
    
    % Misc query functions
	methods
        
        function [ids, labels] = idsByLabel(obj, label, exactMatch)
            % IDSBYLABEL
            %
            % Input:
            %   Label       String to match
            % Optional:
            %   exactMatch  Full or partial label (default: true)
            %
            % Output:
            %   ids         Structure IDs
            %   labels      
            % -------------------------------------------------------------
            
            if nargin < 3
                exactMatch = true;
            end
            if exactMatch
                str = [getServiceRoot(obj.source),...
                    'Structures?$filter=Label eq ''' label, '''&$select=ID'];
            else
                str = [getServiceRoot(obj.source),...
                    'Structures?$filter=contains(Label,''' label...
                    ''')&$select=ID,Label'];
            end
            
            data = webread(str, obj.webOpt);
            
            if isempty(data.value)
                fprintf('No results for %s\n', label);
                return;
            end
            value = cat(1, data.value{:});
            ids = vertcat(value.ID);
            if nargout == 2 && ~exactMatch
                labels = {value.Label};
            else
                labels = label;
            end
        end
        
		function data = annotationsBySection(obj, sections)
            % ANNOTATIONSBYSECTION
            %
            % Input:
            %   sections        Range of Z sections (vector)
            % Output:
            %   data            Query result struct, not parsed
            % ---------------------------------------------------------

			str = ['/Locations?$filter=Z le ' num2str(max(sections)),...
				' and Z ge ', num2str(min(sections)),...
				' and TypeCode eq 1',...
                '&$select=ID,ParentID,X,Y,Z,Radius'];            

			data = webread([getServiceRoot(obj.source), str], obj.webOpt);
		end

		function data = getLinkedIDs(obj, ID)
            % GETLINKEDIDS  From ID, get other linked location IDs
            %
            % Inputs:
            %   ID          The location ID
            %   vitread     Direction (t/f), empty for both
            % 
            % Output:
            %   data        Query result struct, not parsed
            % ---------------------------------------------------------

            str = [getServiceRoot(obj.source),...
                'Locations(' num2str(ID) ')',...
                '&$expand=LocationLinksA'];
            
            data = webread(str, obj.webOpt);
        end

        function [dates, users] = getAnnotationInfo(obj, ID)
            % GETANNOTATIONINFO  Return annotation user data
            %
            % Input:
            %   ID          Structure ID(s)
            %
            % Output:
            %   dates       Last modified dates (and times if 2 outputs)
            %   users       Usernames
            %
            % Use:
            %   [dates, users] = x.getAnnotationInfo(c1.synapses.ID)
            %   dates = x.getAnnotationInfo(7322);
            % -------------------------------------------------------------
            
            dates = [];
            users = [];
            disp('Querying OData for annotation info...');
            for i = 1:numel(ID)
                str = ['Structures(' num2str(ID(i)),...
                ')?$select=Username,LastModified'];
                data = readOData([getServiceRoot(obj.source), str]);
                dt = parseDateTime(data.LastModified);
                dates = cat(1, dates, dt);
                users = cat(1, users, {deblank(data.Username)});
            end
        end

        function data = getLastAnnotations(obj, ID, numAnnotations)
            % GETLASTANNOTATIONS
            %
            % Input:
            %   ID                  StructureID
            %
            % Optional input:
            %   numAnnotations      Number to return (default = 1)
            % -------------------------------------------------------------

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
        
        function data = getUserLastAnnotations(obj, username, numAnnotations)
            % GETUSERLASTLOCATIONS
            %
            % Input:
            %   username            Viking username (char)
            %
            % Optional input:
            %   numAnnotations      Number to return (default = 1)
            % -------------------------------------------------------------
            
            if nargin < 3
                numAnnotations = 1;
            end
            
            str = [getServiceRoot(obj.source),...
                'Locations?$filter=Username eq ''',...
                username, '''&$orderby=LastModified desc ',...
                '&$select=LastModified,ID,ParentID,TypeCode',...
                '&$top=', num2str(numAnnotations)];
            data = webread(str, obj.webOpt);
            data = cat(1, data.value{:});
        end
        
        function T = getUserLastStructures(obj, username, numStructures)
            % GETUSERLASTSTRUCTURES
            %
            % Input:
            %   username            Viking username (char)
            %
            % Optional input:
            %   numStructures       Number to return (default = 1)
            % -------------------------------------------------------------
            str = [getServiceRoot(obj.source), 'Structures?',...
                   '$filter=Username eq ''', username,...
                   '''&$select=ID,TypeID&$orderby=LastModified desc'];
            if nargin == 3
                str = [str, '&$top=', num2str(numStructures)];
            end
            data = webread(str, obj.webOpt);
            data = cat(1, data.value{:});
            T = table(vertcat(data.ID), vertcat(data.TypeID),...
                'VariableNames', {'ID', 'TypeID'});
        end
        
        function str = getLabel(obj, ID)
            % GETLABEL
            %
            % Input:
            %   ID              Structure ID
            %
            % Output:
            %   str             Label in Viking
            % -------------------------------------------------------------
            
            queryURL = [getServiceRoot(obj.source),...
                'Structures(', num2str(ID), ')?$select=Label'];
            data = webread(queryURL, obj.webOpt);
            str = data.Label;
        end
        
        function [usernames, locationIDs] = getUsernames(obj, ID)
            % GETUSERNAMES
            %
            % Input:
            %   ID              Neuron ID
            %
            % Output:
            %   usernames       Annotation user last modified
            %   locationIDs     Corresponding location ID for annotations
            % -------------------------------------------------------------
            queryURL = [getServiceRoot(obj.source),... 
                'Structures(', num2str(ID), ')/Locations?$select=Username,ID'];

            data = readOData(queryURL);
            data = vertcat(data.value{:});
            usernames = cellstr(vertcat(data.Username));
            if nargout == 2
                locationIDs = vertcat(data.ID);
            end
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
            %
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
            % Terminal, Geometry, Username, LastModified
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