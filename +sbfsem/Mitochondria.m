classdef Mitochondria < sbfsem.core.Ultrastructure
    % MITOCHONDRIA
    %
    % Constructor:
    %   obj = Mitochondria(source, ID);
    %   If no ID is specified, all mitochondria will be imported
    %
    % Methods:
    %   obj.update();
    %
    % History:
    %   18Dec2017 - SSP
    %   5Jan2018 - SSP - added Ultrastructure parent class
    %   5Jun2018 - SSP - update import, added geometries and analysis
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
        mito
        mitoIDs
        geometries
    end

    properties (Dependent = true)
        numMito
    end
    
    properties (Constant = true, Hidden = true)
        TYPEID = 246;
    end

    methods
        function obj = Mitochondria(ID, source)
            % If no parent ID, all mitochondria annotations are pulled
            obj@sbfsem.core.Ultrastructure(source);
            
            % Check the inputs
            if nargin < 2
                obj.ID = NaN;
            else
                obj.ID = ID;
            end

            % Fetch the data
            obj.pull();

            obj.geometries = [];

            % Save the time of last update
            obj.queryDate = datestr(now);
        end
        
        function update(obj)
            obj.pull();

            if ~isempty(obj.geometries)
                obj.getGeometries();
            end
        end

        function getGeometries(obj)
            % GETGEOMETRIES  Import ClosedCurve-related OData
            obj.geometries = [];

            for i = 1:obj.numMito
                GeometryClient = sbfsem.io.GeometryOData(...
                    obj.mitoIDs(i), obj.source);
                obj.geometries = [obj.geometries; GeometryClient.pull()];
            end
        end

        function volumes = getVolume(obj)
            % GETVOLUME  Returns mito volumes in micron^3
            [groups, IDs] = findgroups(obj.mito.ParentID);

            radii = splitapply(@sum, obj.mito.Radius, groups);
            areas = 2 * pi * radii.^2;
            volumes = obj.volumeScale(3)/1e3 * areas;
        end
    end

    methods % Dependent property set/get
        function numMito = get.numMito(obj)
            numMito = numel(obj.mitoIDs);
        end
    end
    
    methods (Access = private)
        function pull(obj)
            if isnan(obj.ID)
                importedData = readOData([obj.baseURL,...
                    'Structures?$filter=TypeID eq ' num2str(obj.TYPEID),...
                    '&$select=ID']);
                annotationIDs = struct2array(importedData.value);
                data = [];
                for i = 1:numel(annotationIDs)
                    importedData = readOData([obj.baseURL,...
                        'Structures(', num2str(annotationIDs(i)), ')',...
                        '/Locations?$select=ID,ParentID,X,Y,Z']);
                    data = cat(1, data, struct2array(importedData.value));
                end
            else
                importedData = readOData([obj.baseURL,...
                    'Structures?$filter=TypeID eq ' num2str(obj.TYPEID),...
                    ' and ParentID eq ' num2str(obj.ID),...
                    '&$select=ID']);
            end
            % Catch situations where there are no returned locations
            if isempty(importedData.value)
                fprintf('No mitochondria found for %u\n', obj.ID);
                obj.mito = [];
                return;
            end

            value = cat(1, importedData.value{:});
            IDs = vertcat(value.ID);

            % Create a table of locations associated with each mito
            data = [];
            for i = 1:numel(IDs)
                importedData = readOData([obj.baseURL,...
                    'Structures(', num2str(IDs(i)), ')',...
                    '/Locations?$select=ID,ParentID,X,Y,Z,Radius']);
                value = cat(1, importedData.value{:});
                data = [data; struct2table(value)]; %#ok<AGROW>
            end
            fprintf('Found %u mitochondria\n', numel(unique(data.ParentID)));
            
            obj.mito = data;
            obj.mitoIDs = unique(obj.mito.ParentID);

            % Convert radius to microns
            obj.mito.Radius = obj.volumeScale(1)/1e3 * obj.mito.Radius; 
        end
    end
end