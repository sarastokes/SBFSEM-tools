classdef (Abstract) Node < handle

	properties (Access = public)
		next 
		previous
	end

	properties (SetAccess = protected, GetAccess = public)
        name                        % Readable name/filename
		imData						% Image
    end
    
    methods (Abstract)
        show(obj, ax)
    end

	methods
		function obj = Node(varargin)
			ip = inputParser();
			ip.CaseSensitive = false;
			% image data
			addParameter(ip, 'imData', []);
			% image display name
			addParameter(ip, 'name', [], @ischar);
			parse(ip, varargin{:});
			obj.imData = ip.Results.imData;
			obj.name = ip.Results.name;
		end

		function setName(obj, newName)
			if ischar(newName)
				obj.name = newName;
			elseif isnumeric(newName)
				obj.num2str(newName);
			end
        end
        
        function mat = node2matrix(obj)
            mat = obj.imData;
        end

		% Set/get functions
		function set.next(obj, next)
			obj.next = next;
		end

		function next = get.next(obj)
			next = obj.next;
		end

		function set.previous(obj, previous)
			obj.previous = previous;
		end

		function previous = get.previous(obj)
			previous = obj.previous;
		end
	end
end
