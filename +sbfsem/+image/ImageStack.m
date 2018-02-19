classdef ImageStack < handle
    % IMAGESTACK  Implements a doubly linked list to represent
    % 				a stack of sequential EM images
    %
    % Properties:
    %   head        First node
    %   tail        Last node
    %   numNodes    Number of nodes in stack
    % Transient properties:
    %   handles         UI handles
    %   currentNode     Currently displayed node in UI
    %
    % Methods:
    %   insert(obj, im);
    %   delete(obj, im);
    %   view(obj, flipStack);
    %   A = stack2array(obj, keepRGB);
    %   [tf, n] = find(obj, k);
    %   tf = isEndpoint(obj, node, whichEnd);
    %   v = video(obj, fname, varargin);
    %
    % 29Sept2017 - SSP
      
    properties (Access = public)
        head = [];
        tail = [];
        numNodes
    end
    
    properties (Hidden = true, Transient = true)
        handles = struct();			
        currentNode					
    end
    
    methods
        function obj = ImageStack(imPath, nodes)            
            if nargin < 2
                nodes = [];
            end
            
            if isempty(nodes) && ~isempty(imPath)
                nodes = ls(imPath);
                omits = [];
                for i = 1:size(nodes,1)
                    if ~contains(nodes(i,:), '.png')
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
                        imnodes = cat(1, imnodes,...
                            sbfsem.image.ImageNode([imPath, filesep, nodes(i,:)]));
                    end
                elseif istable(nodes)
                    if ismember('Curve', nodes.Properties.VariableNames)
                        imnodes = cell(0,1);
                        nodes = sortrows(nodes, 'Z');
                        for i = 1:height(nodes)
                            imnodes = cat(1, imnodes,...
                                sbfsem.image.PolygonNode(nodes.Curve{i,:}, nodes.Z(i,:)));
                        end
                        obj.numNodes = height(nodes);
                    end 
                elseif isa(nodes(1), {'ImageNode', 'PolygonNode', 'ClosedCurve'})
                    imnodes = nodes;
                end
                
                % Create the head node
                obj.head = imnodes(1);
                obj.tail = obj.head;
                
                % Insert the rest
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
        
        function A = stack2array(obj, keepRGB)
            % STACK2ARRAY  Convert stack into 3-d or 4-d array
            % keepRGB       default=true, if false converts to bw
            % 29Oct2017 - SSP - todo: clean this code
            
            if nargin < 2
                keepRGB = true;
            end
            
            x = obj.head;
            
            if keepRGB
                A = zeros(obj.numNodes, size(obj.head.node2matrix, 1),...
                    size(obj.head.node2matrix, 2), size(obj.head.node2matrix,3));
                A(1,:,:,:) = obj.head.node2matrix;
            else
                A = zeros(obj.numNodes, size(obj.head.node2matrix,1),...
                    size(obj.head.node2matrix,2));
                A(1,:,:) = rgb2gray(obj.head.node2matrix);
            end
            count = 1;
            
            while ~isempty(x) && ~isempty(x.next)
                x = x.next;
                count = count + 1;
                if keepRGB
                    A(count,:,:,:) = x.node2matrix;
                else
                    A(count,:,:) = squeeze(rgb2gray(x.node2matrix));
                end
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
        
        function v = video(obj, fname, varargin)
            % VIDEO  Save a video of stack
            % 	fname 		'filepath/myvideo.avi'
            % 	flipStack 	[false] head->tail
            % 	invert 		[false] invert colors
            %
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'flipStack', false, @islogical);
            addParameter(ip, 'frameRate', [], @isnumeric);
            addParameter(ip, 'invert', false, @islogical);
            parse(ip, varargin{:});
            
            % Get the image source file if no file path specified
            if ~contains(fname, filesep) 
                ind = strfind(obj.head.filePath, filesep);
                fname = [obj.head.filePath(1:ind(end)-1), filesep, fname];
            end
            
            fh = figure();
            if ip.Results.invert
                set(fh, 'Color', 'k');
            else
                set(fh, 'Color', 'w');
            end
            ax = axes('Parent', fh);
            
            v = VideoWriter(fname);
            if ~isempty(ip.Results.frameRate)
                v.FrameRate = ip.Results.frameRate;
            end
            open(v);
            
            if ip.Results.flipStack
                node = obj.tail();
                node.show(ax);
                while ~isempty(node)
                    node.show(ax);
                    node = node.previous();
                    f = getframe();
                    writeVideo(v, f);
                end
            else
                node = obj.head();
                node.show(ax);
                while ~isempty(node)
                    node.show(ax);
                    node = node.next();
                    f = getframe();
                    writeVideo(v, f);
                end
            end
            close(v);
        end
    end
end


