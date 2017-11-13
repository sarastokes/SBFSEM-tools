classdef Generic < Mosaic
    % The Generic subclass allows quick implementation of new neuron group analyses
    
    properties
        data
        names
    end
    
    properties (Hidden, Transient)
        handles
        jImage
    end
    
    methods
        function obj = Generic()
            % Don't pass a new neuron when creating generic

            obj.names = cell(0, 1);

            createUi(obj);         
        end % constructor

    end % methods
    
    methods (Access = protected)
    % these methods are only used once when first creating object

        function createUi(obj)

            import javax.swing.*;
            import javax.swing.tree.*;


            fh = figure('Name', 'Generic Mosaic Setup',...
                'DefaultUicontrolFontName', 'Segoe Ui',...
                'DefaultUicontrolFontSize', 10,...
                'NumberTitle', 'off',...
                'Menubar', 'off', 'Toolbar', 'off',...
                'Color', 'w');
            obj.handles = struct();
            obj.handles.fh = fh;

            mainLayout = uix.HBox('Parent', obj.handles.fh);
            obj.handles.treeLayout = uix.Panel('Parent', mainLayout);
            uiLayout = uix.VBox('Parent', obj.handles.fh);
            set(mainLayout, 'Widths', [-1 -1]);

            % get the icons
            iconPath = fileparts(mfilename);
            iconPath = [iconPath '\util\icons\'];
            obj.jImage.checked = java.awt.Toolkit.getDefaultToolkit.createImage(...
                [iconPath 'checked.png']);            
            obj.jImage.unchecked = java.awt.Toolkit.getDefaultToolkit.createImage(...
                [iconPath 'unchecked.png']);
            obj.jImage.iconWidth = obj.jImage.unchecked.getWidth;

            obj.makeTree();

            % setup the ui panel
            uicontrol('Parent', uiLayout,...
                'Style', 'text', 'String', 'Parameters included:');
            obj.handles.lst = uicontrol('Parent', uiLayout,...
                'Style', 'listbox',...
                'Enable', 'off');
            obj.handles.pb = uicontrol('Parent', uiLayout,...
                'Style', 'push',...
                'String', 'Update Parameters',...
                'Callback', @updateParams);
            set(uiLayout, 'Heights', [-1 -12 -2]);
        end

        function makeTree(obj)
            % MAKETREE  Creates a checkbox tree of attributes

            % create the nodes
            rootNode = uitreenode('v0', 'root', 'Attributes', [], 0);

            synNode = uitreenode('v0', 'Synapses', 'Synapses', [], 0); 
            rootNode.add(synNode);
            synList = {'ribbon pre', 'ribbon post', 'conv pre', 'conv post',...
                'gap junction', 'desmosome', 'touch', 'gaba fwd',...
                'bip conv pre', 'bip conv post', 'unknown'};
            for ii = 1:length(synList)
                cNode = uitreenode('v0', synList{ii}, synList{ii}, [], 0);
                cNode.setIcon(obj.jImage.unchecked);
                synNode.add(cNode);
            end

            neuronNode = uitreenode('v0', 'Neuron Info', 'Neuron Info:', [], 0);
            rootNode.add(neuronNode);
            neuronList = {'celltype', 'subtype', 'onoff', 'inputs',...
                'strata', 'source', 'annotator'};
            for ii = 1:length(neuronList)
                cNode = uitreenode('v0', neuronList{ii}, neuronList{ii}, [], 0);
                cNode.setIcon(obj.jImage.unchecked);
                neuronNode.add(cNode);
            end

            somaNode = uitreenode('v0', 'Soma info', 'Soma info:', [], 0);
            rootNode.add(somaNode);
            somaList = {'XYZpix', 'XYZum', 'LocationID', 'SomaSize'};
            for ii = 1:length(somaList)
                cNode = uitreenode('v0', somaList{ii}, somaList{ii}, [], 0);
                cNode.setIcon(obj.jImage.unchecked);
                neuronNode.add(cNode);
            end           

            % setup and include java handle
            treeModel = DefaultTreeModel(rootNode);
            obj.handles.tree = uitree('v0');
            obj.handles.tree.setModel(treeModel);
            drawnow;
            set(obj.handles.tree, 'Parent', obj.handles.treeLayout);
            set(obj.handles.tree, 'NodeSelectedCallback', @selectedNode);
            
            obj.handles.jtree = handle(tree.getTree, 'CallbackProperties');
            set(obj.handles.jtree, 'MousePressedCallback', @mousePressCallback);
        end

        function mousePressCallback(~, eventdata) %#ok<INUSD>
            % MOUSEPRESSCALLBACK  Controls checkbox image

            % get the clicked node
            clickX.eventdata.getX;
            clickY.eventdata.getY;
            treePath = obj.handles.jtree.getPathForLocation(clickX, clickY);
            % check if node was clicked
            if ~isempty(treePath)
                if clickX <= (obj.handles.jtree.getPathBounds(treePath).x + iconWidth)
                    node = treePath.getLastPathComponent;
                    nodeValue = node.getValue;
                    switch nodeValue
                    case 'selected'
                        node.setValue('unselected');
                        node.setIcon(obj.jImage.unchecked);
                        obj.handles.jtree.treeDidChange();
                    case 'unselected'
                        node.setValue('selected');
                        node.setIcon(obj.jImage.checked);
                        obj.handles.jtree.treeDidChange();
                    end
                end
            end
        end % mousePressCallback

        function boxSelected(obj, ~, ~)
            nodes = obj.handles.tree.getSelectedNodes;
            node = nodes(1);
            obj.names = [obj.names, node2attribute(node)];
            set(obj.handles.lst, 'String', obj.names);
        end

    end % protected methods
 
end % classdef