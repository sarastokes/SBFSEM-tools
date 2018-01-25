classdef (Abstract) Ultrastructure < handle
% ULTRASTRUCTURE
%
% Description:
%   Abstract class for ultrastructure annotations (mitochondria, axon, etc)
%
% Properties:
%   source          Volume name
%   baseURL         Service root for OData queries
% Protected properties:
%   queryDate       Time of last update from OData
%   TYPEID          Viking StructureType ID - must be defined by subclasses
%
% History:
%   5Jan - SSP - created
% -------------------------------------------------------------------------
    
    properties (SetAccess = private, GetAccess = public)
        source
    end

    properties (SetAccess = protected, GetAccess = public)
        queryDate
    end
    
    properties (Access = protected)
        baseURL
    end
    
    properties (Constant = true, Abstract = true)
        TYPEID
    end
    
    methods
        function obj = Ultrastructure(source)
            obj.source = validateSource(source);
            obj.baseURL = getServiceRoot(source);
        end
    end
end