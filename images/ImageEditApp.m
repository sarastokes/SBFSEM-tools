classdef ImageEditApp < handle
% IMAGEEDITAPP  Edit tools for EM images
%	Mimics the photoshop functions I like to use for EM
%	
% 30Sept2017 - SSP

	properties
		images
		saveDir
	end

	properties (Transient = true, Hidden = true)
		currentNode
		imData
		handles
	end

	methods
		function obj = ImageEditApp(images)
           	validateattributes(images, {'ImageStack'}, {});
            if nargin < 2
                obj.currentNode = images.tail;
            else
                obj.currentNode = images.head;
            end
            obj.createUi();
		end

		function createUi(obj)
			obj.handles.fh = figure('Name', 'Image Edit App',...
				'KeyPressFcn', @obj.onKeyPress);

			pos = get(obj.handles.fh, 'Position');
			set(obj.handles.fh, 'Position', [pos(1)-200, pos(2)-200, 950, 600]);

	        mainLayout = uix.HBoxFlex( ...
                'Parent', obj.handles.fh,...
                'BackgroundColor', 'w');

	        leftLayout = uix.VBox(...
	        	'Parent', leftLayout,...
	        	'BackgroundColor', 'w');
            obj.handles.ax1 = axes( ...
                'Parent', leftLayout,...
                'Color', 'w');
            uiLayout = uix.HBox('Parent', leftLayout);
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
            set(leftLayout, 'Heights', [-12 -1]);

            rightLayout = uix.VBox(...
            	'Parent', rightLayout,...
            	'BackgroundColor', 'w');
            obj.handles.ax2 = axes( ...
                'Parent', rightLayout,...
                'Color', 'w');
            fcnPanel = uix.HBox('Parent', rightLayout);
            obj.handles.fcnList = uicontrol(...
            	'Parent', fcnPanel,...
            	'Style', 'listbox',...
            	'String', {'Gamma'});
            sliderPanel = uix.VBox('Parent', fcnPanel);
            obj.handles.sl = uicontrol(...
            	'Parent', sliderPanel,...
            	'Min', 0, 'Max', 2,...
            	'SliderStep', [0.05 0.1]);
            obj.handles.slj = findjobj(obj.handles.sl);
            set(obj.handles.slj,...
            	'AdjustmentValueChangedCallback', @obj.onChangedSlider);
            set(rightLayout, 'Heights', [-12 -1]); 

            obj.currentNode.show(obj.handles.ax);
            obj.imData = obj.currentNode.imData;



            set(findall(obj.handles.fh, 'Style', 'push'),...
                'BackgroundColor', 'w',...
                'FontSize', 10,...
                'FontWeight', 'bold');
		end
	end

	methods (Access = private)
		function updateGamma(obj, newGamma)
			% TODO decide when to use image vs image data
			I = rgb2gray(obj.imData);
			I = imadjust(I, [], [], newGamma);
			imshow(I, 'Parent', I);
		end
	end

	methods (Access = private)
		function onKeyPress(obj, ~, event)
			switch event.Key
				case 'rightarrow'
					obj.nextView();
				case 'leftarrow'
					obj.nextView();
			end
		end

		function onChangedSlider(obj, ~, ~)
			value = obj.handles.sl.Value;
			switch obj.handles.fcnList.String{obj.handles.fcnList.Value}
				case 'gamma'
					obj.updateGamma();
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
            obj.imData = obj.currentNode.imData;
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
            obj.imData = obj.currentNode.imData;
            obj.currentNode.show(obj.handles.ax);
            set(obj.handles.tx.frame, 'String', obj.currentNode.name);

        end
    end
end