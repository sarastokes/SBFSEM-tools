classdef ImageStack < handle
% IMAGESTACK  Implements a doubly linked list to represent
% 				a stack of sequential EM images
%
% 29Sept2017 - SSP


properties (Access = public)
	head = [];
	tail = [];
	numNodes
end

properties (Hidden = true, Transient = true)
	handles = struct();			% Quick UI handles
	currentNode					% Currently displayed node in UI
end

	methods
		function obj = ImageStack(nodes, imPath)

			if nargin < 2
				imPath = [];
			end

			if isempty(nodes) && ~isempty(imPath)
				nodes = ls(imPath);
				omits = [];
				for i = 1:size(nodes,1)
					if isempty(strfind(nodes(i,:), '.png'))
						omits = cat(2, omits, i);
					end				
				end
				nodes(omits,:) = [];
				fprintf('Pulled %u files from image folder\n', size(nodes, 1));
				obj.numNodes = size(nodes,1);
			end

			if ~isempty(nodes)

		        if ischar(nodes)
		        	imnodes = cell(0,1);
	        		for i = 1:size(nodes,1)
	        			imnodes = cat(1, imnodes, ImageNode([imPath filesep nodes(i,:)]));
	        		end
	        	elseif isa(nodes(1), 'ImageNode')
	        		imnodes = nodes;
	        	end

				obj.head = imnodes(1);
				obj.tail = obj.head;

				for i = 2:length(imnodes)
					insert(obj, imnodes(i));
				end

				obj.currentNode = obj.head;
            end
		end

		function insert(obj, im)
			im.next = obj.head;
			if ~isempty(obj.head)
				obj.head.previous = im;
			end
			obj.head = im;
			im.previous = [];
		end

		function delete(obj, im)
			if ~isempty(x.previous)
				im.previous.next = im.next;
			else
				obj.head = next;
			end

			if im == obj.tail
				obj.tail = im.previous;
			end
		end

		function view(obj, flipStack)
			if nargin < 2
				flipStack = false;
			end
			if flipStack
				obj.currentNode = obj.tail;
			end

		end

		function [tf, n] = find(obj, k)
			x = obj.head;
			while ~isempty(x) && all(x.data~=k)
				x = x.next;
			end
			if isempty(x)
				tf = false;
				n = [];
			else
				tf = true;
				n = x;
			end
		end

		function tf = isEndpoint(obj, node, whichEnd)
			if nargin < 3
				whichEnd = 'head';
			end

			switch whichEnd
				case 'head'
					tf = isequal(obj.head.fname, node.fname);
				case 'tail'
					tf = isequal(obj.tail.fname, node.fname);
			end
		end

		function setHead(obj, head)
			obj.head = head;
		end

		function head = getHead(obj)
			head = obj.head;
		end

		function setTail(obj, tail)
			obj.tail = tail;
		end

		function tail = getTail(obj)
			tail = obj.tail;
		end
	end
end


