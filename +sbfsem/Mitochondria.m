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
    % 18Dec2017 - SSP
    
    properties (SetAccess = private)
        ID
        mito
    end
    
    properties (Constant = true)
        TYPEID = 246;
    end
   
    methods
        function obj = Mitochondria(source, ID)
            % If no parent ID, all mitochondria annotations are pulled
            obj@sbfsem.core.Ultrastructure(source);
            
            % Check the inputs
            if nargin < 2
                obj.ID = NaN;
            else
                assert(isinteger(ID), 'ID must be an integer');
                obj.ID = ID;
            end
            
            % Fetch the data
            obj.pull();
        end
        
        function update(obj)
            obj.pull();
        end
    end
    
    methods (Access = private)
        function pull(obj)
            if isnan(obj.ID)
                importeddata = readOData([obj.baseURL,...
                    'Structures?$filter=TypeID eq ' num2str(obj.TYPEID),...
                    '&$select=ID']);
                annotationIDs = struct2array(importeddata.value);
                data = [];
                for i = 1:numel(annotationIDs)
                    importeddata = readOData([obj.baseURL,...
                        'Structures(', num2str(annotationIDs(i)), ')',...
                        '/Locations?$select=ID,ParentID,X,Y,Z']);
                    data = cat(1, data, struct2array(importeddata.value));
                end
            else
                % TODO: mitochondria associated with specific parent ID
            end
            
            obj.mito = data;
            
            % Save the time of last update
            obj.queryDate = datestr(now);
        end
    end
end