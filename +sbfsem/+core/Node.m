classdef Node < handle
% NODE 
%
% Description
%	Single node in a doubly-linked list
%
% History:
%	14Feb2018 - created from ImageNode
% ----------------------------------------------------------------------

	properties (Access = public)
		next
		previous
	end

	methods
		function obj = Node()
			% Do nothing
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