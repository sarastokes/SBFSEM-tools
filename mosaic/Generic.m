classdef Generic < Mosaic
    % The Generic subclass allows quick implementation of new neuron group analyses
    
    properties
        data
        names
    end
    
    properties (Hidden, Transient)
        handles
    end
    
    methods
        function obj = Generic(Neuron)

            makeTree(obj);

        end % constructor

    end % methods
    
    methods (Access = protected)
    % these methods are only used once when first creating object
        function makeTree()
            % MAKETREE  Creates a checkbox tree of attributes
            import javax.swing.*;
            import javax.swing.tree.*;

            f = figure('Name', 'Choose attributes to include',...
                'Units', 'normalized');

            % get the icons, convert to java
            [I, map] = checkedIcon;
            javaImage_checked = im2java(I, map);
            [I, map] = uncheckedIcon;
            javaImage_unchecked = im2java(I, map);
            iconWidth = javaimage_unchecked.getWidth;


            % create the nodes
            rootNode = uitreenode('v0', 'root', 'Attributes', [], 0);

            synNode = uitreenode('v0', '', 'Synapses', [], 0); 
            rootNode.add(synNode);
            synList = {'ribbon pre', 'ribbon post', 'conv pre', 'conv post',...
                'gap junction', 'desmosome', 'touch', 'gaba fwd',...
                'bip conv pre', 'bip conv post', 'unknown'};
            for ii = 1:length(synList)
                cNode = uitreenode('v0', '', synList{ii}, [], 0);
                cNode.setIcon(javaImage_unchecked);
                synNode.add(cNode);
            end

            neuronNode = uitreenode('v0', '', 'Neuron Info:', [], 0);
            rootNode.add(neuronNode);
            neuronList = {'celltype', 'subtype', 'onoff', 'inputs', 'strata', 'source'};
            for ii = 1:length(neuronList)
                cNode = uitreenode('v0', '', neuronList{ii}, [], 0);
                cNode.setIcon(javaImage_unchecked);
                neuronNode.add(cNode);
            end

            somaNode = uitreenode('v0', '', 'Soma info:', [], 0);
            rootNode.add(somaNode);
            somaList = {'XYZpix', 'XYZum', 'LocationID', 'SomaSize'};
            for ii = 1:length(somaList)
                cNode = uitreenode('v0', '', somaList{ii}, [], 0);
                cNode.setIcon(javaImage_unchecked);
                neuronNode.add(cNode);
            end
            

            % setup and include java handle
            treeModel = DefaultTreeModel(rootNode);
            tree = uitree('v0');
            tree.setModel(treeModel);
            jtree = handle(tree.getTree, 'CallbackProperties');
            drawnow;
            set(tree, 'Units', 'normalized',...
                'Position', [0 0 1 0.5]);
            set(tree, 'NodeSelectedCallback', @selectedNode);
            set(jtree, 'MousePressedCallback', @mousePressCallback);
        end

        function makeNodes()
        end

        function mousePressCallback(hTree, eventdata)
            % MOUSEPRESSCALLBACK  Controls checkbox image

            % get the clicked node
            clickX.eventdata.getX;
            clickY.eventdata.getY;
            treePath = jtree.getPathForLocation(clickX, clickY);
            % check if node was clicked
            if ~isempty(treePath)
                if clickX <= (jtree.getPathBounds(treePath).x + iconWidth)
                    node = treePath.getLastPathComponent;
                    nodeValue = node.getValue;
                    switch nodeValue
                    case 'selected'
                        node.setValue('unselected');
                        node.setIcon(javaImage_unchecked);
                        jtree.treeDidChange();
                    case 'unselected'
                        node.setValue('selected');
                        node.setIcon(javaImage_checked);
                        jtree.treeDidChange();
                    end
                end
            end
        end % mousePressCallback

        function boxSelected(tree, eventdata)
            nodes = tree.getSelectedNodes;
            node = nodes(1);
            attribute = node2attribute(node);
        end

        function node2attribute(obj, ~, ~)
            % SETATTRIBUTES  Define the info for the data table

        end
    end % protected methods
end % classdef