function exportSceneDAE(axHandle, fName)
% EXPORTSCENEDAE
%
% Inputs:
%	axHandle 		axis containing patches
%	fName 			filename
%
% Note:
%   Will open a dialog box to get target file path. The '.dae' extension
%   is automatically appended if not already included.
%
% History:
%   2Jan2018 - SSP - created from exportDAE.m
% -------------------------------------------------------------------------

% Setup file name and path
fPath = uigetdir();

if isempty(fPath)
    return;
else
    % Check for correct file extension
    if strcmp(fName(end-2:end), '.dae')
        fName = [fName, '.dae'];
    end
    fPath = [fPath, filesep, fName];
end
fprintf('Saving to %s\n', fPath);

% TODO: convert any existing lines/surfaces
allPatches = findall(axHandle, 'Type', 'patch');

% Get the unique tags
graphNames = unique(arrayfun(@(x) get(x, 'Tag'),...
    allPatches, 'UniformOutput', false));
fprintf('Saving meshes:');
disp(graphNames)

allFV = containers.Map();
% Condense each tag into a single mesh
for i = 1:numel(graphNames)
    patches = findall(axHandle, 'Tag', graphNames{i});
    F = arrayfun(@(x) get(x, 'Faces'), patches,...
        'UniformOutput', false);
    V = arrayfun(@(x) get(x, 'Vertices'), patches,...
        'UniformOutput', false);
    % Create into a single faces/vertices struct
    FV = struct('faces', vertcat(F{:}), 'vertices', vertcat(V{:}));
    % FV = concatenateMeshes(FV);
    allFV(graphNames{i}) = FV;
end

% Create the COLLADA document
DOM = com.mathworks.xml.XMLUtils.createDocument('COLLADA');
rootNode = DOM.getDocumentElement;

rootNode.setAttribute(...
    'xmlns','http://www.collada.org/2005/11/COLLADASchema');
rootNode.setAttribute('version', '1.4.1');

asset = rootNode.appendChild(DOM.createElement('asset'));

dateNode = asset.appendChild(DOM.createElement('created'));
dateNode.appendChild(DOM.createTextNode(...
    datestr(now, 'yyyy-mm-ddTHH:MM:SSZ')));

contributor = asset.appendChild(DOM.createElement('contributor'));
authorNode = contributor.appendChild(...
    DOM.createElement('authoring_tool'));
authorNode.appendChild(DOM.createTextNode('SBFSEMtools'));

unitNode = asset.appendChild(DOM.createElement('unit'));
unitNode.setAttribute('meter', '0.1');
unitNode.setAttribute('name', 'meter');

upAxis = asset.appendChild(DOM.createElement('up_axis'));
upAxis.appendChild(DOM.createTextNode('Z_UP'));

libScenes = rootNode.appendChild(DOM.createElement('library_visual_scenes'));
visualScene = libScenes.appendChild(DOM.createElement('visual_scene'));
visualScene.setAttribute('id', 'ID2');

sceneNode = visualScene.appendChild(DOM.createElement('node'));
sceneNode.setAttribute('name', 'SBFSEMtools');

libNodes = rootNode.appendChild(DOM.createElement('library_nodes'));

libGeometries = rootNode.appendChild(DOM.createElement('library_geometries'));

% Add the faces and vertices of each patch in axis
for i = 1:numel(graphNames)
    % Get the faces and vertices matching the current Tag
    FV = allFV(graphNames{i});
    F = FV.faces;
    V = FV.vertices;
    fprintf('%s - %u faces and %u vertices\n',... 
        graphNames{i}, numel(F), numel(V));
    
    % Add to the COLLADA document
    node = sceneNode.appendChild(DOM.createElement('node'));
    node.setAttribute('id', id('', 3, i));
    node.setAttribute('name', ['instance_', graphNames{i}]);
    
    matrix = node.appendChild(DOM.createElement('matrix'));
    matrix.appendChild(DOM.createTextNode(sprintf('%d ', eye(4))));
    
    instanceNode = node.appendChild(DOM.createElement('instance_node'));
    instanceNode.setAttribute('url', id('#', 4, i));
    
    node = libNodes.appendChild(DOM.createElement('node'));
    node.setAttribute('id',  id('', 4, i));
    node.setAttribute('name', graphNames{i});
    
    instanceGeometry = node.appendChild(...
        DOM.createElement('instance_geometry'));
    instanceGeometry.setAttribute('url', id('#', 5, i));
    
    bindMaterial = instanceGeometry.appendChild(...
        DOM.createElement('bind_material'));
    bindMaterial.appendChild(DOM.createElement('technique_common'));
    
    geometry = libGeometries.appendChild(DOM.createElement('geometry'));
    geometry.setAttribute('id', id('', 5, i));
    
    meshNode = geometry.appendChild(DOM.createElement('mesh'));
    source = meshNode.appendChild(DOM.createElement('source'));
    source.setAttribute('id', id('', 6, i));
    
    floatArray = source.appendChild(DOM.createElement('float_array'));
    floatArray.setAttribute('id', id('', 7, i));
    floatArray.setAttribute('count', num2str(numel(V)));
    floatArray.appendChild(DOM.createTextNode(sprintf('%g ', V')));
    
    techniqueCommon = source.appendChild(...
        DOM.createElement('technique_common'));
    
    accessor = techniqueCommon.appendChild(DOM.createElement('accessor'));
    accessor.setAttribute('count', num2str(size(V, 1)));
    accessor.setAttribute('source', id('#', 7, i));
    accessor.setAttribute('stride', '3');
    
    for j = {'X', 'Y', 'Z'}
        param = accessor.appendChild(DOM.createElement('param'));
        param.setAttribute('name', j);
        param.setAttribute('type', 'float');
    end
    
    vertices = meshNode.appendChild(DOM.createElement('vertices'));
    vertices.setAttribute('id', id('', 8, i));
    vertexInput = vertexInput.appendChild(DOM.createElement('input'));
    vertexInput.setAttribute('semantic', 'POSITION');
    vertexInput.setAttribute('source', id('#', 6, i));
    
    triangles = meshNode.appendChild(DOM.createElement('triangles'));
    triangles.setAttribute('count', num2str(size(F, 1)));
    triangleInput = triangles.appendChild(DOM.createElement('input'));
    triangleInput.setAttribute('offset', '0');
    triangleInput.setAttribute('semantic', 'VERTEX');
    triangleInput.setAttribute('source', id('#', 8, i));
    
    p = triangles.appendChild(DOM.createElement('p'));
    p.appendChild(DOM.createTextNode(sprintf('%d ', (F-1)')));
end

scene = rootNode.appendChild(DOM.createElement('scene'));
instanceVisualScene = scene.appendChild(...
    DOM.createElement('instance_visual_scene'));
instanceVisualScene.setAttribute('url', '#ID2');

fid = fopen(fPath, 'w');
fprintf(fid, '%s', xmlwrite(DOM));
fclose(fid);

    function s = id(p, n, i)
        % ID  Generate some quick IDs
        s = sprintf('%sID%d', p, n+(i-1)*10);
    end
end