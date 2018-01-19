function exportDAE(filename, varargin)
	% EXPORTDAE  Export render to .dae for Blender
	%
	% Input:
	%	filename 		path to .dae file
	%	V 				vertices
	%	F 				faces
	%
	% 20Dec2017 - SSP

	DOM = com.mathworks.xml.XMLUtils.createDocument('COLLADA');

	rootNode = DOM.getDocumentElement;
	rootNode.setAttribute(...
        'version', '1.4.1');
	rootNode.setAttribute(...
        'xmlns', 'http://www.collada.org/2005/11/COLLADASchema');

	assetNode = rootNode.appendChild(...
		DOM.createElement('asset'));

    % Defines units for mesh
	unitNode = assetNode.appendChild(...
		DOM.createElement('unit'));
	unitNode.setAttribute('meter', '1');
	unitNode.setAttribute('name', 'meter');

    % Which way is up
	upaxisNode = assetNode.appendChild(...
		DOM.createElement('up_axis'));
	upaxisNode.appendChild(...
		DOM.createTextNode('Z_UP'));

    visualScenes = rootNode.appendChild(...
        DOM.createElement('library_visual_scenes'));
    visualScene = visualScenes.appendChild(...
        DOM.createElement('visual_scene'));
    visualScene.setAttribute('id', 'ID2');
    
    sketchup = visualScene.appendChild(...
        DOM.createElement('node'));
    sketchup.setAttribute('name', 'SketchUp');
    
    libraryNodes = rootNode.appendChild(...
        DOM.createElement('library_nodes'));
    
    libraryGeometries = rootNode.appendChild(...
        DOM.createElement('library_geometries'));
    
    for i = 1:2:numel(varargin)
        V = varargin{i};
        F = varargin{i+1};
        
        node = sketchup.appendChild(...
            DOM.createElement('node'));
        node.setAttribute(...
            'id', id('', 3, i));
        node.setAttribute(...
            'name', sprintf('instance_%d', i-1));
        
        matrixNode = node.appendChild(...
            DOM.createElement('matrix'));
        matrixNode.appendChild(...
            DOM.createTextNode(sprintf('%d', eye(4))));
        
        instanceNode = node.appendChild(...
            DOM.createElement('instance_node'));
        instanceNode.setAttribute(...
            'url', id('#', 4, i));
                
        node = libraryNodes.appendChild(...
            DOM.createElement('node'));
        node.setAttribute(...
            'id', id('', 4, i));
        node.setAttribute(...
            'name', sprintf('skp%d', i-1));
        
        instanceGeometry = node.appendChild(...
            DOM.createElement('instance_geometry'));
        instanceGeometry.setAttribute(...
            'url', id('#', 5, i));
        
        bindMaterial = instanceGeometry.appendChild(...
            DOM.createElement('bind_material'));
        bindMaterial.appendChild(...
            DOM.createElement('technique_common'));
               
        geometry = libraryGeometries.appendChild(...
            DOM.createElement('geometry'));
        geometry.setAttribute('id', id('',5,i));

        mesh = geometry.appendChild(DOM.createElement('mesh'));
        
        source = mesh.appendChild(...
            DOM.createElement('source'));
        source.setAttribute('id', id('',6,i));
        
        floatArray = source.appendChild(...
            DOM.createElement('float_array'));
        floatArray.setAttribute(...
            'id', id('', 7, i));        
        floatArray.setAttribute(...
            'count', num2str(numel(V)));
        floatArray.appendChild(...
            DOM.createTextNode(sprintf('%g', V')));
        
        techniqueCommon = source.appendChild(...
            DOM.createElement('technique_common'));
        
        accessor = techniqueCommon.appendChild(...
            DOM.createElement('accessor'));
        accessor.setAttribute(...
            'count', num2str(size(V,1)));
        accessor.setAttribute(...
            'source', id('#', 7, i));
        accessor.setAttribute(...
            'stride', '3');
        
        for name = {'X', 'Y', 'Z'}
            param = accessor.appendChild(...
                DOM.createElement('param'));
            param.setAttribute('name', name);
            param.setAttribute('source', id('#', 7, i));
        end
        
        vertices = mesh.appendChild(...
            DOM.createElement('vertices'));
        vertices.setAttribute('id', id('', 8, i));
        
        input = vertices.appendChild(...
            DOM.createElement('input'));
        input.setAttribute('offset', '0');
        input.setAttribute('semantic', 'VERTEX');
        input.setAttribute('source', id('#', 6, i));
        triangles = mesh.appendChild(...
            DOM.createElement('triangles'));
        triangles.setAttribute('count', num2str(size(F, 1)));
        
        input = triangles.appendChild(DOM.createElement('input'));
        input.setAttribute('offset', '0');
        input.setAttribute('semantic', 'POSITION');
        input.setAttribute('source', id('#', 8, i));
        
        p = triangles.appendChild(DOM.createElement('p'));
        p.appendChild(DOM.createTextNode(sprintf('%d', (F-1)')));    
    end
    
    scene = rootNode.appendChild(...
        DOM.createElement('scene'));
    instanceVisualScene = scene.appendChild(...
        DOM.createElement('instance_visual_schene'));
    instanceVisualScene.setAttribute('url', '#ID2');
    
    f = fopen(filename, 'w');
    fprintf(f, '%s', xmlwrite(DOM));
    fclose(f);
    
    
    function s = id(p, n, i)
        s = sprintf('%sID%d', p, n+(i-1)/2*10);
    end
end
        
        
        