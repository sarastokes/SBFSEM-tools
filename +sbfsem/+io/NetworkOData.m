classdef NetworkOData < handle
    % NETWORKODATA
    %
    % Description:
    %   Supports queries of connectivity networks centered around one neuron.
    %
    % Constructor:
    %   obj = NetworkOData(ID, source, numHops);
    %
    % Inputs:
    %   ID              Neuron Structure ID
    %   source          Volume name or abbreviation
    % Optional inputs:
    %   numHops         How many degrees of connections (default = 1)
    %
    % Properties
    %   ID              Neuron Structure ID
    %   numHops         N degrees of connections
    % Dependent properties:
    %   queryStr        OData query string
    %
    % Methods
    %   pull            Run query, return data as nodes, edges
    %
    % History:
    %	25Mar2018 - SSP
    % -------------------------------------------------------------------------
    
    properties (Access = private)
        source
        baseURL
        ID
    end
    
    properties (Access = public)
        numHops
    end
    
    properties (Dependent = true, Hidden = true)
        queryStr
    end
    
    methods
        function obj = NetworkOData(ID, source, numHops)
            % NETWORKODATA  Constructor
            obj.source = validateSource(source);
            
            % Input checking
            assert(isnumeric(obj.ID), 'ID must be an integer');
            if numel(obj.ID) > 1
                error('Multiple IDs not supported with JSON query');
            end
            obj.ID = ID;
            
            if nargin == 3
                obj.numHops = numHops;
            else
                obj.numHops = 1;
            end
            
            % Remove the OData part from query
            obj.baseURL = [getServerName(), '/', obj.source];
        end
        
        function set.numHops(obj, numHops)
            assert(isnumeric(numHops) && numel(numHops) == 1,...
                'Input a single integer');
            obj.numHops = numHops;
        end
        
        function value = get.queryStr(obj)
            value = [obj.baseURL,...
                sprintf('/export/network/json?id=%u&hops=%u', obj.ID, obj.numHops)];
        end
        
        function data = pull(obj)
            % PULL
            data = readOData(obj.queryStr);
        end
    end
end