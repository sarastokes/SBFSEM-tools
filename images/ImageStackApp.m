classdef ImageStackApp < handle
    
    properties (Hidden = true, Transient = true)
        images
        currentNode
        handles
    end
    
    methods
        
        function obj = ImageStackApp(images, ~)
            validateattributes(images, {'ImageStack'}, {});

            if nargin < 2
                obj.currentNode = images.tail;
            else
                obj.currentNode = images.head;
            end

            obj.createUi();
        end
        
        function createUi(obj)
            obj.handles.fh = figure('Name', 'Image Stack View',...
                'KeyPressFcn', @obj.onKeyPress);
            pos = get(obj.handles.fh, 'Position');
            obj.handles.fh.Position = [pos(1), pos(2)-200, 550, 600];
            
            mainLayout = uix.VBoxFlex( ...
                'Parent', obj.handles.fh,...
                'BackgroundColor', 'w');
            obj.handles.ax = axes( ...
                'Parent', mainLayout,...
                'Color', 'w');
            uiLayout = uix.HBox('Parent', mainLayout);
            obj.handles.pb.prev = uicontrol(uiLayout,...
                'Style', 'push',...
                'String', '<--',...
                'Callback', @obj.onViewSelectedPrevious);
            obj.handles.tx.frame = uicontrol(uiLayout,...
                'Style', 'text',...
                'BackgroundColor', 'w',...
                'FontSize', 10,...
                'String', obj.currentNode.name);
            obj.handles.pb.prev = uicontrol(uiLayout,...
                'Style', 'push',...
                'String', '-->',...
                'Callback', @obj.onViewSelectedNext);
            set(mainLayout, 'Heights', [-12 -1]);

            obj.currentNode.show(obj.handles.ax);
            
            set(findall(obj.handles.fh, 'Style', 'push'),...
                'BackgroundColor', 'w',...
                'FontSize', 10,...
                'FontWeight', 'bold');
        end
    end
    
    methods (Access = private)
        function onKeyPress(obj, ~, event)
            switch event.Key
                case 'rightarrow'
                    obj.nextView();
                case 'leftarrow'
                    obj.previousView();
            end
        end
        
        function onViewSelectedPrevious(obj, ~, ~)
            obj.previousView();
        end
        
        function previousView(obj)
            if isempty(obj.currentNode.previous)
                return;
            end
            
            obj.currentNode = obj.currentNode.previous;
            obj.currentNode.show(obj.handles.ax);
            set(obj.handles.tx.frame, 'String', obj.currentNode.name);
        end
        
        function onViewSelectedNext(obj, ~, ~)
            obj.nextView();
        end
        
        function nextView(obj)
            if isempty(obj.currentNode.next)
                return;
            end
            
            obj.currentNode = obj.currentNode.next;
            obj.currentNode.show(obj.handles.ax);
            set(obj.handles.tx.frame, 'String', obj.currentNode.name);
        end
    end
end