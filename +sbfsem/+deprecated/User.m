classdef User < handle

    properties (SetAccess = private)
        username
        client
    end

    methods
        function obj = User(username, source)
            obj.username = username;
            obj.client = sbfsem.io.OData(source);
        end

        function IDs = getRecent(obj, varargin)

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'ID', [], @isnumeric);
            addParameter(ip, 'N', 5, @isnumeric);
            parse(ip, varargin{:});

            structureID = ip.Results.ID;

            if ~isempty(structureID)
                obj.x.getLastModified(structureID, ip.Results.N);
            end
        end
    end
end
