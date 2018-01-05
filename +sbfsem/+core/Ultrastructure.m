classdef (Abstract) Ultrastructure < handle
    
    properties (SetAccess = private, GetAccess = public)
        source
        queryDate
    end
    
    properties (Access = private)
        baseURL
    end
    
    properties (Constant = true, Abstract = true)
        % All subclasses must define a Viking TypeID
        TYPEID
    end
    
    methods
        function obj = Ultrastructure(source)
            obj.source = validateSource(source);
            obj.baseURL = getServiceRoot(source);
        end
    end
end