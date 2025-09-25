%% renderSynapseMarkersGUI.m
% Created using Microsoft Copilot, using RenderApp.m and synapseSphere.m
% codes written by Sara Patterson. Andrea S. Bordt.

% September 25, 2025

% To run this code, type
% >> renderSynapseMarkersGUI()

function renderSynapseMarkersGUI()
    % RENDERSYNAPSEMARKERSGUI
    % GUI-based script to render neuron and overlay 2D synapse markers

    % Step 1–4: Get volume and cell ID
    prompt = {'Enter volume code (t/i/n/c):', ...
              'Enter cell ID (e.g., 6219):'};
    dlgTitle = 'Neuron Setup';
    dims = [1 35];
    defInput = {'i', '6219'};
    answer = inputdlg(prompt, dlgTitle, dims, defInput);

    if isempty(answer), return; end

    volumeCode = lower(answer{1});
    cellID = str2double(answer{2});
    objName = sprintf('c%d%s', cellID, volumeCode);

    % Step 5: Create neuron and render
    neuron = Neuron(cellID, volumeCode, true);
    assignin('base', objName, neuron);
    app = RenderApp(volumeCode);
    neuron.build();
    neuron.render('ax', app.ax);

    % Step 6–10: Synapse and marker styling
    prompt = {'Enter synapse type (e.g., RibbonPost):', ...
              'Enter FaceColor RGB (e.g., [0.2 0.8 0.4]):', ...
              'Enter MarkerSize (e.g., 12):', ...
              'Enter EdgeColor RGB (e.g., [0 0 0]):', ...
              'Enter Edge Thickness (LineWidth, e.g., 1.5):'};
    dlgTitle = 'Synapse Marker Styling';
    defInput = {'RibbonPost', '[0.2 0.8 0.4]', '12', '[0 0 0]', '1.5'};
    answer = inputdlg(prompt, dlgTitle, dims, defInput);

    if isempty(answer), return; end

    synType = answer{1};
    faceColor = str2num(answer{2}); %#ok<ST2NM>
    markerSize = str2double(answer{3});
    edgeColor = str2num(answer{4}); %#ok<ST2NM>
    edgeThickness = str2double(answer{5});

    % Step 11: Plot synapse markers
    xyz = neuron.getSynapseXYZ(synType);
    scatter3(app.ax, xyz(:,1), xyz(:,2), xyz(:,3), ...
        markerSize, ...
        'MarkerEdgeColor', edgeColor, ...
        'MarkerFaceColor', faceColor, ...
        'LineWidth', edgeThickness, ...
        'Tag', sprintf('%s_%s', objName, synType));

    fprintf('Rendered %s with synapses: %s\n', objName, synType);
end
