classdef RenderApp < handle
    % RENDERAPP
    %
    % Description:
    %   UI for viewing renders and creating scenes for figures
    %
    % Constructor:
    %   obj = RenderApp(source);
    %
    % Example:
    %   RenderApp('i');
    %
    % Todo:
    %   - Check for duplicate neurons
    %   - Synapses
    %   - Legend colors
    %
    % See also:
    %   GRAPHAPP, IMAGESTACKAPP, IPLDEPTHAPP, NEURON
    %
    % History:
    %   5Jan2018 - SSP
    %   19Jan2018 - SSP - menubar, replaced table with checkbox tree
    %   12Feb2018 - SSP - IPL boundaries and scale bars
    %   26Apr2018 - SSP - Added NeuronCache option to Import menu
    %   7Oct2018 - SSP - New context tab for importing markers, cones
    %   30Oct2018 - SSP - Fully debugged boundary and gap markers
    %   6Nov2018 - SSP - Color by stratification added
    %   19Nov2018 - SSP - Last modified location added
    % ---------------------------------------------------------------------

    properties (SetAccess = private)
        neurons             % Neuron objects
        IDs                 % IDs of neuron objects
        source              % Volume name
        volumeScale         % Volume dimensions (nm/pix)
        mosaic              % Cone mosaic (empty until loaded)
        iplBound            % IPL Boundary structure (empty until loaded)
        vessels             % Blood vessels (empty until loaded)
    end

    properties (SetAccess = private, Hidden = true, Transient = true)
        % UI handles
        figureHandle        % Parent figure handle
        ax                  % Render axis
        neuronTree          % Checkbox tree
        lights              % Light handles
        scaleBar            % Scale bar (empty until loaded)

        % UI properties
        isInverted          % Is axis color inverted

        % UI view controls
        azel = [-35, 30];
        zoomFac = 0.9;
        panFac = 0.02;

        % XY offset applied to volume on neuron import
        xyOffset = [];      % Loaded on first use, if needed

        % Transformation to XY offsets
        transform = sbfsem.core.Transforms.Viking;
    end

    properties (Constant = true, Hidden = true)
        DEFAULTALPHA = 0.6;
        BUBBLE_SIZE = 1/30;
        UI_WIDTH = 140;     % Pixels
        SYNAPSES = false;
        SOURCES = {'NeitzTemporalMonkey','NeitzInferiorMonkey','MarcRC1'};
        CACHE = [fileparts(fileparts(mfilename('fullname'))), filesep, 'data'];
        COLORMAPS = {'haxby', 'parula', 'winter', 'hsv', 'antijet',...
            'cubicl', 'viridis', 'redblue', 'bone', 'isolum (colorblind)',...
            'ametrine (colorblind)'};
    end

    methods
        function obj = RenderApp(source)
            % RENDERAPP
            %
            % Description:
            %   Constructor, opens UI and optional volume select UI
            %
            % Optional inputs:
            %   source          Volume name or abbreviation (char)
            %
            % Note:
            %   If no volume name is provided, a listbox of available
            %   volumes will appear before the main UI opens
            % -------------------------------------------------------------
            if nargin > 0
                obj.source = validateSource(source);
            else
                [selection, selectedSource] = listdlg(...
                    'PromptString', 'Select a source:',...
                    'Name', 'RenderApp Source Selection',...
                    'SelectionMode', 'single',...
                    'ListString', obj.SOURCES);
                if selectedSource
                    obj.source = obj.SOURCES{selection};
                    fprintf('Running with %s\n', obj.source);
                else
                    warning('No source selected... exiting');
                    return;
                end
            end

            obj.neurons = containers.Map();
            if ~strcmp(obj.source, 'RC1')
                obj.iplBound.GCL = sbfsem.builtin.GCLBoundary(obj.source, true);
                obj.iplBound.INL = sbfsem.builtin.INLBoundary(obj.source, true);
            else
                obj.iplBound.GCL = []; obj.iplBound.INL = [];
            end
            obj.vessels = [];
            obj.createUI();

            try
                obj.volumeScale = getODataScale(obj.source);
            catch
                obj.volumeScale = loadCachedVolumeScale(obj.source);
            end

            obj.isInverted = false;
            obj.xyOffset = [];
        end
    end

    % Neuron callback methods
    methods (Access = private)
        function onAddNeuron(obj, ~, ~)
            % ONADDNEURON  Callback for adding neurons via edit box
            inputBox = findobj(obj.figureHandle, 'Tag', 'InputBox');
            
            % No input detected
            if isempty(inputBox.String)
                return;
            end

            % Separate neurons by commas
            str = deblank(inputBox.String);
            if nnz(isletter(deblank(inputBox.String))) > 0
                warning('Neuron IDs = integers separated by commas');
                return;
            end
            str = strsplit(str, ',');

            % Clear out accepted input string so user doesn't accidentally
            % add the neuron twice while program runs.
            set(inputBox, 'String', '');

            % Import the new neuron(s)
            for i = 1:numel(str)
                newID = str2double(str{i});
                obj.updateStatus(sprintf('Adding c%u', newID));
                didImport = obj.addNeuron(newID);
                if ~didImport
                    fprintf('Skipped c%u\n', newID);
                    continue;
                end

                newColor = findall(obj.ax, 'Tag', obj.id2tag(newID));
                newColor = get(newColor(1), 'FaceColor');

                obj.addNeuronNode(newID, newColor, true);
                obj.updateStatus();
                % Update the plot after each neuron imports
                drawnow;
            end
        end
        
        function onAddNeuronJSON(obj, ~, ~)
            % ADDNEURONJSON  Load JSON neuron
            [fName, fPath] = uigetfile('.json',...
                'Choose JSON file(s)', 'MultiSelect', 'on');
            if ischar(fName)
                fName = {fName};
            end
            for i = 1:numel(fName)
                jsonFile = fName{i};
                newID = str2double(jsonFile(2:end-4));
                obj.updateStatus(sprintf('Adding %u', newID));
                
                didImport = obj.addNeuron([fPath, jsonFile], 'JSON');
                if ~didImport
                    fprintf('Skipped %u\n', newID);
                    continue;
                end
                               
                newColor = findall(obj.ax, 'Tag', obj.id2tag(newID));
                newColor = get(newColor(1), 'FaceColor');

                obj.addNeuronNode(newID, newColor, false);
                obj.updateStatus();
                
                drawnow;
            end
        end

        function onUpdateNeuron(obj, ~, evt)
            % ONUPDATENEURON  Update the underlying OData and render

            % Save the view azimuth and elevation
            [az, el] = view(obj.ax);

            % Get the target ID and neuron
            ID = obj.tag2id(evt.Source.Tag);
            neuron = obj.neurons(num2str(ID));

            % Update the OData and the 3D model
            obj.updateStatus('Updating OData');
            try
                neuron.update();
            catch ME
                switch ME.identifier
                    case 'MATLAB:webservices:HTTP404StatusCodeError'
                        obj.updateStatus(sprintf('c%u not found', num2str(ID)));
                    case 'MATLAB:webservices:UnknownHost'
                        obj.updateStatus('Check Connection');
                    otherwise
                        obj.updateStatus('Unknown Error');
                        disp(ME.identifier);
                end
                return
            end
            obj.updateStatus('Updating model');
            neuron.build();
            
            % Save the properties of existing render and axes
            oldPatch = findobj(obj.ax, 'Tag', evt.Source.Tag);
            oldColor = get(oldPatch, 'FaceColor');
            oldAlpha = get(oldPatch, 'FaceAlpha');
            % Delete the old one and render a new one
            delete(oldPatch);
            obj.updateStatus('Updating render');
            neuron.render('ax', obj.ax,...
                'FaceAlpha', oldAlpha);
            newPatch = findobj(obj.ax, 'Tag', evt.Source.Tag);
            
            % Apply vertex cdata mapping
            if strcmp(oldColor, 'interp')
                newCData = clipStrataCData(newPatch.Vertices,...
                    obj.iplBound.INL, obj.iplBound.GCL);
                set(newPatch, 'FaceVertexCData', newCData,...
                    'FaceColor', 'interp');
            else
                set(newPatch, 'FaceVertexCData',...
                    repmat(oldColor, [size(newPatch.Vertices, 1), 1]),...
                    'FaceColor', oldColor);
            end
            % Return to the original view azimuth and elevation
            view(obj.ax, az, el);
            obj.updateStatus('');
        end

        function onRemoveNeuron(obj, ~, evt)
            % ONREMOVENEURON  Callback to trigger neuron removal

            if numel(obj.neuronTree.SelectedNodes) ~= 1
                warning('More than one node selected');
                return
            else
                node = obj.neuronTree.SelectedNodes;
            end
            node.UIContextMenu = [];
            % Get the neuron ID
            ID = obj.tag2id(evt.Source.Tag);
            obj.removeNeuron(ID, node);
        end

        function onExportNeuron(obj, ~, ~)
            % ONEXPORTNEURON  Export Neuron objects to base workspace

            tags = obj.neurons.keys;
            for i = 1:numel(tags)
                assignin('base', sprintf('c%u', tags{i}),...
                    obj.neurons(tags{i}));
            end
        end

        function onSetTransform(obj, src, ~)
            % ONSETTRANSFORM  
            if ~isempty(obj.neurons)
                warndlg('Changing the Transform with existing neurons is not recommended.');
            end
            switch src.String{src.Value}
                case 'Viking'
                    obj.transform = sbfsem.core.Transforms.Viking;
                case 'Local'
                    obj.transform = sbfsem.core.Transforms.SBFSEMTools;
            end
        end
    end

    % Node tree callbacks - apply to just one neuron
    methods (Access = private)
    
        function onNodeChecked(obj, ~, evt)
            % ONNODECHECKED  Toggles visibility of patches

            % The Matlab wrapper returns only selection paths, not nodes
            if isempty(evt.SelectionPaths)
                % No nodes are checked
                set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
            elseif numel(evt.SelectionPaths) == 1
                if strcmp(evt.SelectionPaths.Name, 'Root')
                    % All nodes are checked
                    set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'on');
                else % Only one node is checked
                    set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
                    set(findall(obj.ax, 'Tag', evt.SelectionPaths(1).Name),...
                        'Visible', 'on');
                end
            elseif numel(evt.SelectionPaths) > 1
                % Some but not all nodes are checked
                set(findall(obj.ax, 'Type', 'patch'), 'Visible', 'off');
                for i = 1:numel(evt.SelectionPaths)
                    set(findall(obj.ax, 'Tag', evt.SelectionPaths(i).Name),...
                        'Visible', 'on');
                end
            end
        end
        
        function onShowLastModified(obj, ~, evt)
            % ONSHOWLASTMODIFIED  Draw bubble around last modified location
            
            % Delete any existing last modified annotations
            obj.deleteLastMod();  
            
            neuron = obj.neurons(num2str(obj.tag2id(evt.Source.Tag)));
            XYZ = neuron.id2xyz(neuron.getLastModifiedID());
            if isempty(XYZ)
                obj.updateStatus('Last Modified Not Found!');
                return;
            end
            
            axLims = obj.getLimits(obj.ax);
            axSize = mean(abs(axLims(:,2) - axLims(:,1)));
            radius = obj.BUBBLE_SIZE * axSize;
            
            % Make the annotation
            [X, Y, Z] = sphere();
            X = radius * X; Y = radius * Y; Z = radius * Z;
            X = X + XYZ(1); Y = Y + XYZ(2); Z = Z + XYZ(3);
            
            p = surf(X, Y, Z, 'Parent', obj.ax,...
                'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none',...
                'FaceAlpha', 0.3, 'FaceLighting', 'gouraud',...
                'Tag', 'LastModified');
            c = uicontextmenu();
            uimenu(c, 'Label', 'Delete', 'Callback', @obj.deleteLastMod);
            p.UIContextMenu = c;
        end

        function onColorByStrata(obj, ~, evt)
            % ONCOLORBYSTRATA  Color by stratification

            obj.updateStatus('Coloring...');
            h = findall(obj.ax, 'Tag', evt.Source.Tag);
            set(h, 'FaceVertexCData',...
                clipStrataCData(h.Vertices, obj.iplBound.INL, obj.iplBound.GCL));
            shading(obj.ax, 'interp');
            obj.updateStatus();
        end

        function onChangeColor(obj, ~, evt)
            % ONCHANGECOLOR  Change a render's color

            newColor = selectcolor('hCaller', obj.figureHandle);

            if ~isempty(newColor) && numel(newColor) == 3
                h = findall(obj.ax, 'Tag', evt.Source.Tag);

                set(h, 'FaceColor', newColor,...
                    'FaceVertexCData', repmat(newColor, [size(h.Vertices,1), 1]));
            end
        end

        function onSetTransparency(obj, src, evt)
            % ONSETTRANSPARENCY  Change patch face alpha

            if isempty(src.Tag)
                % Apply to all neurons (from toolbar)
                newAlpha = str2double(src.Label);
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceAlpha', newAlpha);
            elseif strcmp(src.Tag, 'DefaultAlpha')
                % Apply to all neurons (from popup menu)
                newAlpha = str2double(src.String{src.Value});
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceAlpha', newAlpha);
            elseif strcmp(src.Tag, 'SurfAlpha')
                newAlpha = str2double(src.String{src.Value});
                set(findall(obj.ax, 'Type', 'surface'),...
                    'FaceAlpha', newAlpha);
            else
                % Apply to a single neuron
                newAlpha = str2double(src.Label);
                set(findall(obj.ax, 'Tag', evt.Source.Tag),...
                    'FaceAlpha', newAlpha);
            end
        end        
    end

    % Plot callback methods
    methods (Access = private)

        function onToggleGrid(obj, src, ~)
            % TOGGLEGRID  Show/hide the grid
            if src.Value == 1
                grid(obj.ax, 'on');
            else
                grid(obj.ax, 'off');
            end
        end

        function onToggleAxes(obj, ~, ~)
            % ONTOGGLEAXES  Show/hide axes
            if sum(obj.ax.XColor) == 3
                newColor = [0 0 0];
            else
                newColor = [1 1 1];
            end
            set(obj.ax, 'XColor', newColor,...
                'YColor', newColor, 'ZColor', newColor);
        end

        function onSetRotation(obj, src, ~)
            % ONSETROTATION
            switch src.Tag
                case 'XY1'
                    view(obj.ax, 2);
                case 'XY2'
                    view(0, -90);
                case 'YZ'
                    view(90, 0);
                case 'XZ'
                    view(obj.ax, 0, 0);
                case '3D'
                    view(obj.ax, 3);
            end
        end

        function onSetLimits(obj, src, evt)
            % ONSETLIMITS
            data = src.Data;
            ind = evt.Indices;
            % Whether to use custom or auto axis limits
            tof = data(ind(1), 1);
            % Get the axis name
            str = [src.RowName{ind(1)}, 'Lim'];
            if tof{1}
                set(obj.ax, str, [data{ind(1), 2}, data{ind(1), 3}]);
            elseif ind(2) == 1
                axis(obj.ax, 'tight');
                newLimit = get(obj.ax, str);
                data{ind(1), 2} = newLimit(1);
                data{ind(1), 3} = newLimit(2);
                src.Data = data;
            end
        end

        function onToggleLights(obj, src, ~)
            % ONTOGGLELIGHTS  Turn lighting on/off

            if src.Value == 0
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'gouraud');
            else
                set(findall(obj.ax, 'Type', 'patch'),...
                    'FaceLighting', 'none');
            end
        end

        function onToggleInvert(obj, ~, ~)
            % ONINVERT  Invert figure colors
            if ~obj.isInverted
                bkgdColor = 'k'; frgdColor = 'w';
                set(obj.ax, 'GridColor', [0.85, 0.85, 0.85]);
                obj.isInverted = true;
            else
                bkgdColor = 'w'; frgdColor = 'k';
                set(obj.ax, 'GridColor', [0.15 0.15 0.15]);
                obj.isInverted = true;
            end
            set(obj.ax, 'Color', bkgdColor,...
                'XColor', frgdColor,...
                'YColor', frgdColor,...
                'ZColor', frgdColor);
            set(obj.ax.Parent,...
                'BackgroundColor', bkgdColor);
        end

        function onSetNextColor(obj, src, ~)
            % ONSETNEXTCOLOR  Open UI to choose color, reflect change

            newColor = selectcolor('hCaller', obj.figureHandle);

            if ~isempty(newColor) && numel(newColor) == 3
                set(src, 'BackgroundColor', newColor);
            end
        end

        function onChangeColormap(obj, src, ~)
            % ONCHANGECOLORMAP  Change colormap used for stratification
            newMap = src.String{src.Value};
            h = findobj(obj.figureHandle, 'Tag', 'MapLevels');
            colormap(obj.ax, obj.getColormap(newMap, str2double(h.String)));
        end
        
        function onInvertMap(obj, ~, ~)
            % ONINVERTMAP  Reverse the colormap scaling
            currentMap = colormap(obj.ax);
            colormap(obj.ax, flipud(currentMap));
        end
        
        function onKeyPress_CMapLevels(obj, src, evt)
            % ONKEYPRESS_CMAPLEVELS  Callback to check for 'enter' press
            if strcmp(evt.Key, 'return')
                try
                    N = str2double(src.String);
                catch
                    warndlg('Levels must be number between 2 and 256');
                    set(src, 'String', '256');
                    N = 256;
                end
                h = findobj(obj.figureHandle, 'Tag', 'CMaps');
                colormap(obj.ax, obj.getColormap(h.String{h.Value}, N));
            end
        end
    end

    % Non-neuron component callbacks
    methods (Access = private)

        function onAddCones(obj, src, ~)
            % ONIMPORTCONES
            % See also: SBFSEM.BUILTIN.CONEMOSAIC, SBFSEM.CORE.CLOSEDCURVE
            if isempty(obj.mosaic)
                obj.updateStatus('Loading mosaic...');
                obj.mosaic = sbfsem.builtin.ConeMosaic.fromCache('i');
                obj.updateStatus('');
            end

            obj.toggleCones(src.Tag(4:end), src.Value);
        end
        
        function onAddBloodVessels(obj, src, ~)
            % ONADDBLOODVESSELS
            % See also: SBFSEM.BUILTIN.VASCULATURE, SBFSEM.CORE.BLOODVESSEL
            
            if src.Value
                if isempty(obj.vessels)
                    obj.vessels = sbfsem.builtin.Vasculature(obj.source);
                    if ~isempty(obj.vessels.vessels)
                        obj.vessels.render(obj.ax);
                    end
                else
                    set(findall(obj.figureHandle, 'Tag', 'BloodVessel'),...
                        'Visible', 'on');
                end
            else
                set(findall(obj.figureHandle, 'Tag', 'BloodVessel'),...
                    'Visible', 'off');
            end
        end

        function onAddScaleBar(obj, src, ~)
            % ONSCALEBAR
            % See also: SBFSEM.UI.SCALEBAR3

            switch src.String
                case 'Add ScaleBar'
                    obj.scaleBar = sbfsem.ui.ScaleBar3(obj.ax);
                    src.String = 'Remove ScaleBar';
                case 'Remove ScaleBar'
                    obj.scaleBar.delete();
                    obj.scaleBar = [];
                    src.String = 'Add ScaleBar';
            end
        end

        function onAddBoundary(obj, src, ~)
            % ONADDBOUNDARY  Add IPL Boundary markers
            if isempty(obj.iplBound.GCL)
                obj.updateStatus('Importing boundaries');

                obj.iplBound.GCL = sbfsem.builtin.GCLBoundary(obj.source, true);
                obj.iplBound.INL = sbfsem.builtin.INLBoundary(obj.source, true);
                
                obj.updateStatus('');
            end
            obj.toggleBoundary(src.Tag, src.Value);
        end
        
        function onAddGap(obj, src, ~)
            % ONADDGAP  Show/hide 915-936 gap surface
            if src.Value
                x = get(obj.ax, 'XLim');
                y = get(obj.ax, 'YLim');
                z = obj.volumeScale(3) * 1e-3 * 922;
                hold(obj.ax, 'on');
                F = [1:3; 2:4; 3,4,1];
                V = [x(1), y(1), z; x(2), y(2), z; x(1), y(2), z; x(2), y(1), z];
                patch(obj.ax, 'Faces', F, 'Vertices', V,...
                    'FaceAlpha', 0.3, 'EdgeColor', 'none',...
                    'Tag', 'Gap');  
            else
                delete(findall(obj.ax, 'Tag', 'Gap'));
            end
        end
    end

    % External callbacks
    methods (Access = private)

        function onOpenGraphApp(obj, ~, evt)
            % ONOPENVIEW  Open a single neuron analysis view
            % See also: GRAPHAPP

            neuron = obj.neurons(num2str(obj.tag2id(evt.Source.Tag)));
            obj.updateStatus('Opening view');
            GraphApp(neuron);
            obj.updateStatus('');
        end

        function onGetSomaStats(obj, ~, evt)
            % ONGETSOMASTATS  Open SomaStatsView
            neuron = obj.neurons(num2str(obj.tag2id(evt.Source.Tag)));
            SomaStatsView(neuron);
        end
        
        function onGetStratification(obj, ~, evt)
            % ONGETSTRATIFICATION  Run iplDepth, graph results
            neuron = obj.neurons(num2str(obj.tag2id(evt.Source.Tag)));
            obj.updateStatus('Analyzing...');
            neuronColor = get(findobj(obj.ax, 'Tag', evt.Source.Tag), 'FaceColor');
            if ischar(neuronColor)
                neuronColor = 'k';
            end
            iplDepth(neuron, 'numBins', 25, 'includeSoma', true,...
                     'Color', neuronColor);
            obj.updateStatus('');
        end

        function onExportImage(obj, src, ~)
            % ONEXPORTIMAGE  Save renders as an image

            % Export figure to new window without uicontrols
            newAxes = obj.exportFigure();
            set(newAxes.Parent, 'InvertHardcopy', 'off');

            % Open a save dialog to get path, name and extension
            [fName, fPath] = uiputfile(...
                {'*.jpeg'; '*.png'; '*.tiff'},...
                'Save image as a JPEG, PNG or TIFF');

            % Catch when user cancels out of save dialog
            if isempty(fName) || isempty(fPath)
                return;
            end

            % Save by extension type
            switch fName(end-2:end)
                case 'png'
                    exten = '-dpng';
                case 'peg'
                    exten = '-djpeg';
                case 'iff'
                    exten = '-dtiff';
            end

            if isempty(strfind(src.Label, 'high res'))
                print(newAxes.Parent, [fPath, fName], exten);
            else
                print(newAxes.Parent, [fPath, fName], exten, '-r600');
            end
            fprintf('Saved as: %s\n', [fPath, fName]);
            delete(newAxes.Parent);
        end

        function onExportCollada(obj, ~, ~)
            % ONEXPORTCOLLADA  Export the scene as a .dae file
            % See also: EXPORTSCENEDAE

            % Prompt user for file name and path
            [fName, fPath] = uiputfile('*.dae', 'Save as');
            % Catch when user cancels out of save dialog
            if isempty(fName) || isempty(fPath)
                return;
            end
            exportSceneDAE(obj.ax, [fPath, fName]);
        end

        function onExportFigure(obj, ~, ~)
            % ONEXPORTFIGURE  Copy figure to new window
            obj.exportFigure();
        end
    end

    % Neuron private functions
    methods (Access = private)
        function didImport = addNeuron(obj, newID, importType)
            % ADDNEURON  Add a new neuron and render
            % See also: NEURON
            
            if nargin < 3
                importType = 'OData';
            end
            
            switch importType
                case 'OData'
                    [neuron, didImport] = obj.addNeuronFromOData(newID);
                case 'JSON'
                    [neuron, didImport] = obj.addNeuronFromJSON(newID);
            end
            
            if ~didImport
                return;
            end

            % Build and render the 3D model
            obj.updateStatus(sprintf('Rendering c%u', neuron.ID));
            if isempty(neuron.model)
                neuron.build();
            end

            colorBox = findobj(obj.figureHandle, 'Tag', 'NextColor');
            neuron.render('ax', obj.ax,...
                'FaceColor', colorBox.BackgroundColor,...
                'FaceAlpha', obj.DEFAULTALPHA);
            view(obj.ax, obj.azel(1), obj.azel(2));
            
            h = findobj(obj.ax, 'Tag', obj.id2tag(neuron.ID));
            set(h, 'FaceVertexCData',... 
                repmat(h.FaceColor, [size(h.Vertices,1), 1]));
            
            % If all is successful, add to neuron lists
            obj.neurons(num2str(neuron.ID)) = neuron;
            obj.IDs = cat(2, obj.IDs, neuron.ID);
            didImport = true;
        end

        function [neuron, didImport] = addNeuronFromOData(obj, newID)
            % ADDNEURONFROMODATA  Import a neuron from OData
            try
                neuron = Neuron(newID, obj.source, obj.SYNAPSES, obj.transform);
                didImport = true;
            catch ME
                switch ME.identifier
                    case 'SBFSEM:NeuronOData:invalidTypeID'
                        obj.updateStatus(sprintf('%u not a Cell', newID));
                    case 'MATLAB:webservices:HTTP404StatusCodeError'
                        obj.updateStatus(sprintf('c%u not found!', newID));
                    case 'MATLAB:webservices:UnknownHost'
                        obj.updateStatus('Check Connection');
                    otherwise
                        fprintf('Unidentified error: %s\n', ME.identifier);
                        obj.updateStatus(sprintf('Error for c%u', newID));
                end
                
                neuron = [];
                didImport = false;
            end
        end

        function newNode = addNeuronNode(obj, ID, ~, onlineMode)
            % ADDNEURONNODE  Add new neuron node to checkbox tree

            newNode = uiextras.jTree.CheckboxTreeNode(...
                'Parent', obj.neuronTree,...
                'Name', obj.id2tag(ID),...
                'Checked', true);

            c = uicontextmenu('Parent', obj.figureHandle);
            if onlineMode
                uimenu(c, 'Label', 'Update',...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onUpdateNeuron);
            end
            uimenu(c, 'Label', 'Remove Neuron',...
                'Tag', obj.id2tag(ID),...
                'Callback', @obj.onRemoveNeuron);
            uimenu(c, 'Label', 'Change Color',...
                'Tag', obj.id2tag(ID),...
                'Callback', @obj.onChangeColor);
            t = uimenu(c, 'Label', 'Change Transparency',...
                'Tag', obj.id2tag(ID));
            for i = 0.1:0.1:1
                uimenu(t, 'Label', num2str(i),...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onSetTransparency)
            end
            if ~isempty(obj.iplBound.GCL)
                uimenu(c, 'Label', 'Color by strata',...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onColorByStrata);
            end
            if onlineMode
                uimenu(c, 'Label', 'Show Last Modified',...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onShowLastModified);
            end
            uimenu(c, 'Label', 'Open GraphApp',...
                'Tag', obj.id2tag(ID),...
                'Callback', @obj.onOpenGraphApp);
            a = uimenu(c, 'Label', 'Analysis',...
                'Tag', obj.id2tag(ID));
            if ~isempty(obj.iplBound.GCL)
                uimenu(a, 'Label', 'Get Stratification',...
                    'Tag', obj.id2tag(ID),...
                    'Callback', @obj.onGetStratification);
            end
            uimenu(a, 'Label', 'Get Soma Stats',...
                'Tag', obj.id2tag(ID),...
                'Callback', @obj.onGetSomaStats);
            set(newNode, 'UIContextMenu', c);
        end

        function removeNeuron(obj, ID, node)
            % REMOVENEURON  Remove a neuron from tree and figure

            % Delete from checkbox tree
            delete(node);
            % Clear out neuron data
            obj.neurons(num2str(ID)) = [];
            obj.IDs(obj.IDs == ID) = [];
            % Delete the patch from the render
            delete(findall(obj.ax, 'Tag', obj.id2tag(ID)));
        end
    end

    % Render component private functions
    methods (Access = private)

        function toggleRender(obj, tag, toggleState)
            % TOGGLERENDER  Hide/show render
            set(findall(obj.ax, 'Tag', tag) , 'Visible', toggleState);
        end

        function toggleCones(obj, coneType, value)
            % TOGGLECONES  Hide/show cone mosaic
            if value
                obj.mosaic.plot(coneType, obj.ax, coneType);
            else
                delete(findall(gcf, 'Tag', coneType));
            end
        end

        function toggleBoundary(obj, name, value)
            % TOGGLEBOUNDARY  Hide/show boundary
            h = obj.iplBound.(name).getSurfaceHandle(obj.ax);
            if value
                if isempty(h)
                    obj.iplBound.(name).plot('ax', obj.ax);
                    set(obj.iplBound.(name).getSurfaceHandle(obj.ax),...
                        'FaceAlpha', 0.3);
                else
                    set(h, 'Visible', 'on');
                end
            else
                set(h, 'Visible', 'off');
            end
        end
              
        function deleteLastMod(varargin)
            % DELETELASTMOD  Delete last modified location annotation
            obj = varargin{1};
            delete(findall(obj.ax, 'Tag', 'LastModified'));
        end
    end

    % Misc private functions
    methods (Access = private)
        function updateStatus(obj, str)
            % UPDATESTATUS  Update status text
            if nargin < 2
                str = '';
            else
                assert(ischar(str), 'Status updates must be char');
            end
            set(findobj(obj.figureHandle, 'Tag', 'StatusBox'), 'String', str);
            drawnow;
        end
        
        function matchAxes(obj)
            % MATCHAXES  Reset axes limits to user specified values
            h = findobj(obj.figureHandle, 'Type', 'uitable');
            data = get(h, 'Data');
            names = get(h, 'RowName');
            for i = 1:3
                if data{i,1}
                    set(obj.ax, [names{i}, 'Lim'], [data{i,2}, data{i,3}]);
                end
            end
        end

        function newAxes = exportFigure(obj)
            % EXPORTFIGURE  Open figure in a new window

            newAxes = exportFigure(obj.ax);
            axis(newAxes, 'tight');
            hold(newAxes, 'on');

            % Keep only the visible components
            delete(findall(newAxes, 'Type', 'patch', 'Visible', 'off'));

            % Match the plot modifiers
            set([newAxes, newAxes.Parent], 'Color', obj.ax.Color);
            obj.setLimits(newAxes, obj.getLimits(obj.ax));
            set(newAxes.Parent, 'InvertHardcopy', 'off');
        end
    end

    % User interface setup
    methods (Access = private)
        function createUI(obj)
            % CREATEUI  Setup the main user interface, runs only once
            obj.figureHandle = figure(...
                'Name', 'RenderApp',...
                'Color', 'w',...
                'NumberTitle', 'off',...
                'DefaultUicontrolBackgroundColor', 'w',...
                'DefaultUicontrolFontSize', 10,...
                'DefaultUicontrolFontName', 'Segoe UI',...
                'Menubar', 'none',...
                'Toolbar', 'none',...
                'KeyPressFcn', @obj.onKeyPress);

            % Toolbar options
            obj.createToolbar();

            % Main layout with 2 panels (UI, axes)
            mainLayout = uix.HBoxFlex('Parent', obj.figureHandle,...
                'BackgroundColor', 'w', 'Tag', 'MainLayout',...
                'SizeChangedFcn', @obj.onLayoutResize);

            % Create the user interface panel and tabs
            tabGroup = uitabgroup('Parent', mainLayout);
            uiLayout = uix.VBox(...
                'Parent', uitab(tabGroup, 'Title', 'Neurons'),...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5, 'Padding', 5);
            obj.createNeuronTab(uiLayout);
            
            if ~strcmp(obj.source, 'RC1')
                contextLayout = uix.VBox(...
                    'Parent', uitab(tabGroup, 'Title', 'Context'),...
                    'BackgroundColor', 'w',...
                    'Spacing', 0, 'Padding', 5);
                obj.createContextTab(contextLayout);
            end

            ctrlLayout = uix.VBox(...
                'Parent', uitab(tabGroup, 'Title', 'Plot'),...
                'BackgroundColor', 'w',...
                'Spacing', 5, 'Padding', 5);
            obj.createControlTab(ctrlLayout);

            % Rotation/zoom/pan modes require container with pixels prop
            % Using Matlab's uipanel between render axes and HBoxFlex
            axesPanel = uipanel(mainLayout, 'BackgroundColor', 'w');
            obj.createAxes(axesPanel);

            set(mainLayout, 'Widths', [-1 -3]);
        end

        function createAxes(obj, parentHandle)
            % CREATEAXES  Create the render plot axes

            obj.ax = axes('Parent', parentHandle);
            hold(obj.ax, 'on');
            shading(obj.ax, 'interp');
            grid(obj.ax, 'on');
            axis(obj.ax, 'equal', 'tight');
            view(obj.ax, 3);
            xlabel(obj.ax, 'X'); ylabel(obj.ax, 'Y'); zlabel(obj.ax, 'Z');
            colormap(obj.ax, haxby(256));

            % Set the lighting
            obj.lights = [light(obj.ax), light(obj.ax)];
            lightangle(obj.lights(1), 45, 30);
            lightangle(obj.lights(2), 225, 30);
        end

        function createNeuronTab(obj, parentHandle)
            % CREATENEURONTAB  Main render control/interaction panel
            uicontrol(parentHandle,...
                'Style', 'text',...
                'String', obj.source);

            % Create the neuron table
            obj.neuronTree = uiextras.jTree.CheckboxTree(...
                'Parent', parentHandle,...
                'RootVisible', false,...
                'CheckboxClickedCallback', @obj.onNodeChecked);

            % Add/remove neurons
            pmLayout = uix.HBox('Parent', parentHandle,...
                'BackgroundColor', 'w',...
                'Spacing', 5);
            idLayout = uix.VBox('Parent', pmLayout,...
                'BackgroundColor', [1 1 1],...
                'Spacing', 5);
            uicontrol(idLayout,...
                'Style', 'text',...
                'String', 'IDs:');
            uicontrol(idLayout,...
                'Style', 'edit',...
                'Tag', 'InputBox',...
                'TooltipString', 'Input ID(s) separated by commas',...
                'String', '');
            buttonLayout = uix.VBox('Parent', pmLayout,...
                'BackgroundColor', 'w');
            uicontrol(buttonLayout,...
                'Style', 'push',...
                'String', '+',...
                'FontWeight', 'bold',...
                'FontSize', 20,...
                'TooltipString', 'Add neuron(s) in editbox',...
                'Callback', @obj.onAddNeuron);
            uicontrol(buttonLayout,...
                'Style', 'push',...
                'String', ' ',...
                'Tag', 'NextColor',...
                'BackgroundColor', [0.5, 0, 1],...
                'TooltipString', 'Click to change next neuron color',...
                'Callback', @obj.onSetNextColor);
            set(buttonLayout, 'Heights', [-1.2 -.8])
            set(pmLayout, 'Widths', [-1.2, -0.8])

            uicontrol(parentHandle,...
                'Style', 'text',...
                'String', ' ',...
                'Tag', 'StatusBox',...
                'FontAngle', 'italic');

            set(parentHandle, 'Heights', [-.5 -5 -1.5 -.5]);
        end

        function createContextTab(obj, contextLayout)
            % CREATECONTEXTTAB  Interface with non-neuron structures

            LayoutManager = sbfsem.ui.LayoutManager;
            uicontrol(contextLayout,...
                'Style', 'text', 'String', 'Boundary Markers:',...
                'FontWeight', 'bold');
            uicontrol(contextLayout,...
                'Style', 'check', 'String', 'INL Boundary',...
                'Tag', 'INL',...
                'TooltipString', 'Add INL Boundary',...
                'Callback', @obj.onAddBoundary);
            uicontrol(contextLayout,...
                'Style', 'check', 'String', 'GCL Boundary',...
                'TooltipString', 'Add GCL Boundary',...
                'Tag', 'GCL',...
                'Callback', @obj.onAddBoundary);
            uicontrol(contextLayout,...
                'Style', 'check',...
                'String', '915 Gap',...
                'TooltipString', 'Add 915-936 gap',...
                'Callback', @obj.onAddGap);
            uix.Empty('Parent', contextLayout);
            if strcmp(obj.source, 'NeitzTemporalMonkey')
                uicontrol(contextLayout, 'Style', 'text',...
                    'String', 'No cones for TemporalMonkey');
            else
                uicontrol(contextLayout,...
                    'Style', 'text', 'String', 'Cone Mosaic:',...
                    'FontWeight', 'bold');
                uicontrol(contextLayout,...
                    'Style', 'check', 'String', 'S-cones',...
                    'Tag', 'addS',...
                    'Callback', @obj.onAddCones);
                uicontrol(contextLayout,...
                    'Style', 'check', 'String', 'L/M-cones',...
                    'Tag', 'addLM',...
                    'Callback', @obj.onAddCones);
                uicontrol(contextLayout,...
                    'Style', 'check', 'String', 'Unknown',...
                    'Tag', 'addU',...
                    'TooltipString', 'Add cones of unknown type',...
                    'Callback', @obj.onAddCones);
                uicontrol(contextLayout,...
                    'Style', 'check', 'String', 'Blood Vessels',...
                    'TooltipString', 'Import blood vessels',...
                    'Callback', @obj.onAddBloodVessels);
                LayoutManager.verticalBoxWithLabel(contextLayout, 'Transform:',...
                    'Style', 'popup',...
                    'String', {'Viking', 'Local'},...
                    'TooltipString', 'Change transform (MUST REIMPORT NEURONS)',...
                    'Callback', @obj.onSetTransform);
                set(contextLayout, 'Heights',...
                    [-0.5, -1, -1, -1, -1, -0.5, -1, -1, -1, -1, -1.2]);
            end
        end

        function createControlTab(obj, ctrlLayout)
            % CREATECONTROLTAB  Plot aesthetics tab
            LayoutManager = sbfsem.ui.LayoutManager;
            
            uicontrol(ctrlLayout,...
                'Style', 'text', 'String', 'Display options:',...
                'FontWeight', 'bold');
            g = uix.Grid('Parent', ctrlLayout,...
                'BackgroundColor', 'w',...
                'Spacing', 5);
            uicontrol(g, 'String', 'Invert',...
                'Style', 'check',...
                'String', 'Invert background: dark/light',...
                'Callback', @obj.onToggleInvert);
            uicontrol(g, 'String', 'Grid',...
                'Style', 'check',...
                'Value', 1,...
                'TooltipString', 'Show/hide grid',...
                'Callback', @obj.onToggleGrid);
            uicontrol(g, 'String', 'Axes',...
                'Style', 'check',...
                'Value', 1,...
                'TooltipString', 'Show/hide axes',...
                'Callback', @obj.onToggleAxes);
            uicontrol(g, 'String', '2D',...
                'Style', 'check',...
                'TooltipString', 'Toggle b/w 3D and flat 2D',...
                'Callback', @obj.onToggleLights);
            set(g, 'Heights', [-1 -1], 'Widths', [-1, -1]);
            
            uicontrol(ctrlLayout,...
                'Style', 'text', 'String', 'Colormap:',...
                'FontWeight', 'bold');

            cmapLayout = uix.HBox('Parent', ctrlLayout,...
                'BackgroundColor', 'w');
            cmapSubLayout = uix.VBox('Parent', cmapLayout,...
                'BackgroundColor', 'w');
            uicontrol(cmapSubLayout,...
                'Style', 'popup',...
                'String', obj.COLORMAPS,...
                'Tag', 'CMaps',...
                'TooltipString', 'Change colormap used for strata',...
                'Callback', @obj.onChangeColormap);
            uicontrol(cmapSubLayout,...
                'Style', 'push',...
                'String', 'Invert Map',...
                'Callback', @obj.onInvertMap);
            LayoutManager.verticalBoxWithLabel(cmapLayout, 'Levels:',...
                'Style', 'edit',...
                'String', '256',...
                'Tag', 'MapLevels',...
                'TooltipString', 'Set levels for colormap (2-256)',...
                'KeyPressFcn', @obj.onKeyPress_CMapLevels);
            set(cmapLayout, 'Widths', [-1, -0.8]);
            
            LayoutManager.verticalBoxWithLabel(ctrlLayout, 'Transparency:',...
                'Style', 'popup',...
                'String', {'0.1', '0.2', '0.3', '0.4', '0.5',...
                    '0.6', '0.7', '0.8', '0.9', '1'},...
                'Value', 10,...
                'Tag', 'DefaultAlpha',...
                'Callback', @obj.onSetTransparency);
            uix.Empty('Parent', ctrlLayout);
            uicontrol(ctrlLayout,...
                'Style', 'text', 'String', 'View points:',...
                'FontWeight', 'bold');
            rotLayout = uix.HBox('Parent', ctrlLayout,...
                'BackgroundColor', 'w');
            rotations = {'XY1', 'XY2', 'XZ', 'YZ', '3D'};
            for i = 1:numel(rotations)
                uicontrol(rotLayout,...
                    'Style', 'push',...
                    'String', rotations{i},...
                    'Tag', rotations{i},...
                    'Callback', @obj.onSetRotation);
            end
            uicontrol(ctrlLayout,...
                'Style', 'text', 'String', 'Axis Limits');
            uitable(ctrlLayout,...
                'Data', {false, 0, 1; false, 0, 1; false, 0, 1},...
                'ColumnEditable', true,...
                'ColumnWidth', {20, 35, 35},...
                'RowName', {'X', 'Y', 'Z'},...
                'ColumnName', {'', 'Min', 'Max'},...
                'CellEditCallback', @obj.onSetLimits);
            uicontrol(ctrlLayout,...
                'Style', 'push',...
                'String', 'Add ScaleBar',...
                'Callback', @onAddScaleBar);

            set(ctrlLayout, 'Heights',...
                [-0.5, -1.75, -0.5, -1.5, -1.25, -0.2, -0.5, -1, -0.5, -2.5, -0.75]);
        end

        function createToolbar(obj)
            % CREATETOOLBAR  Setup the figure toolbar
            mh.import = uimenu(obj.figureHandle, 'Label', 'Import');
            uimenu(mh.import, 'Label', 'Import .json',...
                'Callback', @obj.onAddNeuronJSON);
            mh.export = uimenu(obj.figureHandle, 'Label', 'Export');
            uimenu(mh.export, 'Label', 'Open in new figure window',...
                'Callback', @obj.onExportFigure);
            uimenu(mh.export, 'Label', 'Export as image',...
                'Callback', @obj.onExportImage);
            uimenu(mh.export, 'Label', 'Export as image (high res)',...
                'Callback', @obj.onExportImage);
            uimenu(mh.export, 'Label', 'Export as COLLADA',...
                'Callback', @obj.onExportCollada);
            uimenu(mh.export, 'Label', 'Send neurons to workspace',...
                'Callback', @obj.onExportNeuron);

            mh.help = uimenu(obj.figureHandle, 'Label', 'Help');
            uimenu(mh.help, 'Label', 'Keyboard controls',...
                'Tag', 'navigation',...
                'Callback', @obj.openHelpDlg);
            uimenu(mh.help, 'Label', 'Neuron analysis',...
                'Tag', 'neuron_info',...
                'Callback', @obj.openHelpDlg);
            uimenu(mh.help, 'Label', 'Annotation import',...
                'Tag', 'import',...
                'Callback', @obj.openHelpDlg);
            uimenu(mh.help, 'Label', 'Scalebar',...
                'Tag', 'scalebar',...
                'Callback', @obj.openHelpDlg);
        end
    end

    % User interface callbacks
    methods (Access = private)
        function onLayoutResize(obj, src, ~)
            % ONLAYOUTRESIZE  Keeps UI panel size constant with figure resizes
            axesWidth = (obj.figureHandle.Position(3)-obj.UI_WIDTH)/obj.UI_WIDTH;
            set(src, 'Widths', [-1, -axesWidth]);
        end

        function onKeyPress(obj, ~, eventdata)
            % ONKEYPRESS  Control plot view with keyboard
            %
            % See also: AXDRAG
            switch eventdata.Character
                case 'h' % help menu
                    [helpStr, dlgTitle] = obj.getInstructions('navigation');
                    helpdlg(helpStr, dlgTitle);
                case 28 % Rotate (azimuth -)
                    obj.azel(1) = obj.azel(1) - 5;
                case 30 % Rotate (elevation -)
                    obj.azel(2) = obj.azel(2) - 5;
                case 31 % Rotate (elevation +)
                    obj.azel(2) = obj.azel(2) + 5;
                case 29 % Rotate (azimuth +)
                    obj.azel(1) = obj.azel(1) + 5;
                case 'a' % Pan (x+)
                    x = get(obj.ax, 'XLim');
                    set(obj.ax, 'XLim', x + obj.panFac * diff(x));
                case 'd' % Pan (x-)
                    x = get(obj.ax, 'XLim');
                    set(obj.ax, 'XLim', x - obj.panFac * diff(x));
                case 'e' % Pan (y+)
                    y = get(gca, 'YLim');
                    set(obj.ax, 'YLim', y + obj.panFac * diff(y));
                case 'q' % Pan (y-)
                    y = get(gca, 'YLim');
                    set(obj.ax, 'YLim', y - obj.panFac * diff(y));
                case 'w' % pan (z+)
                    z = get(obj.ax, 'ZLim');
                    set(obj.ax, 'ZLim', z + obj.panFac * diff(z));
                case 's' % pan (z-)
                    z = get(obj.ax, 'ZLim');
                    set(obj.ax, 'ZLim', z - obj.panFac * diff(z));
                case {'z', 'Z'} % Zoom
                    % SHIFT+Z changes zoom direction
                    if eventdata.Character == 'Z'
                        obj.zoomFac = 1/obj.zoomFac;
                    end

                    x = get(obj.ax, 'XLim');
                    y = get(obj.ax, 'YLim');

                    set(obj.ax, 'XLim',...
                        [0, obj.zoomFac*diff(x)] + x(1)...
                        + (1-obj.zoomFac) * diff(x)/2);
                    set(obj.ax, 'YLim',...
                        [0, obj.zoomFac*diff(y)] + y(1)...
                        + (1-obj.zoomFac) * diff(y)/2);
                case 'm' % Return to original dimensions and view
                    view(obj.ax, 3);
                    axis(obj.ax, 'tight');
                case 'c' % Copy the last click location
                    % Don't copy position if no neurons are plotted
                    if isempty(obj.neurons)
                        return;
                    end

                    % Convert microns to Viking pixel coordinates
                    posMicrons = mean(get(obj.ax, 'CurrentPoint')); %um
                    um2pix = obj.volumeScale/1e3; % nm/pix -> um/pix
                    posViking = posMicrons./um2pix; % pix

                    % Reverse the xyOffset applied on Neuron creation
                    if strcmp(obj.source, 'NeitzInferiorMonkey') && ...
                            obj.transform == sbfsem.core.Transforms.SBFSEMTools
                        if isempty(obj.xyOffset)
                            dataDir = fileparts(fileparts(mfilename('fullpath')));
                            offsetPath = [dataDir,filesep,'data',filesep,...
                                'XY_OFFSET_', upper(obj.source), '.txt'];
                            obj.xyOffset = dlmread(offsetPath);
                        end
                        posViking(3) = round(posViking(3));
                        appliedOffset = obj.xyOffset(posViking(3), 1:2);
                        posViking(1:2) = posViking(1:2) - appliedOffset;
                    end

                    % Format to copy into Viking
                    locationStr = obj.formatCoordinates(posViking);
                    clipboard('copy', locationStr);
                    fprintf('Copied to clipboard:\n %s\n', locationStr);
                otherwise % Unregistered key press
                    return;
            end
            view(obj.ax, obj.azel);
        end

        function openHelpDlg(obj, src, ~)
            % OPENHELPDLG  Opens instructions dialog

            [helpStr, dlgTitle] = obj.getInstructions(src.Tag);
            helpdlg(helpStr, dlgTitle);
        end
    end
    
    methods (Static = true)
        function [neuron, didImport] = addNeuronFromJSON(~, newID)
            % ADDNEURONFROMJSON  Import a neuron saved as a .json file

            try
                neuron = NeuronJSON(newID);
                didImport = true;
            catch ME
                fprintf('addNeuronFromJSON failed with error message:\n\%s\n',...
                    ME.identifier);
                neuron = [];
                didImport = false;
            end
        end
    end

    methods (Static = true)
        function lim = getLimits(ax)
            lim = [get(ax, 'XLim'); get(ax, 'YLim'); get(ax, 'ZLim')];
        end
        
        function setLimits(ax, lim)
            set(ax, 'XLim', lim(1,:), 'YLim', lim(2,:), 'ZLim', lim(3,:));
        end

        function tag = id2tag(id)
            % ID2TAG  Quick fcn for (127 -> 'c127')
            tag = sprintf('c%u', id);
        end

        function id = tag2id(tag)
            % TAG2ID  Quick fcn for ('c127' -> 127)
            id = str2double(tag(2:end));
        end

        function str = formatCoordinates(pos, ds)
            % FORMATCOORDINATES  Sets coordinates to paste into Viking
            if nargin < 2
                ds = 2;
            end
            str = sprintf('X: %.1f Y: %.1f Z: %u DS: %u',...
                pos(1), pos(2), round(pos(3)), ds);
        end
        
        function cmap = getColormap(cmapName, N)
            % GETCOLORMAP  Phase in sbfsem.ui.ColorMaps later
            if nargin < 2
                N = 256;
            end
            
            switch lower(cmapName)
                case 'parula'
                    cmap = parula(N);
                case 'winter'
                    cmap = winter(N);
                case 'bone'
                    cmap = bone(N);
                case 'hsv'
                    cmap = hsv(N);
                case 'antijet'
                    cmap = antijet(N);
                case 'viridis'
                    cmap = viridis(N);
                case 'cubicl'
                    cmap = pmkmp(N, 'CubicL');
                case 'haxby'
                    cmap = haxby(N);
                case 'redblue'
                    cmap = lbmap(N, 'RedBlue');
                case 'ametrine (colorblind)'
                    cmap = ametrine(N);
                case 'isolum (colorblind)'
                    cmap = isolum(N);
            end
        end

        function [str, dlgTitle] = getInstructions(helpType)
            % GETINSTRUCTIONS  Return instructions as multiline string
            switch helpType
            case 'navigation'
                str = sprintf(['NAVIGATION CONTROLS:\n',...
                    '\nROTATE: arrow keys\n',...
                    '   Azimuth: left, right\n',...
                    '   Elevation: up, down\n',...
                    '\nZOOM: ''z''\n',...
                    '   To switch directions, press SHIFT+Z once\n',...
                    '\nPAN:\n',...
                    '   X-axis: ''a'' and ''d''\n',...
                    '   Y-axis: ''q'' and ''e''\n',...
                    '\nRESET axis: ''m''\n',...
                    '   Z-axis: ''w'' and ''s''\n',...
                    '\nCOPY location to clipboard:\n'...
                    '   Click on figure then press ''c''\n',...
                    '\nHELP: ''h''\n']);
                dlgTitle = 'Navigation Instructions';
            case 'neuron_info'
                    str = sprintf(['NEURON ANALYSES:\n',...
                    '\nRight click on a neuron in left panel for options.\n',...
                    '\nAPPEARANCE:\n',...
                    '\tColor by strata shows stratification\n',...
                    '\t\tModify appearance in PLOT tab\n',...
                    '\t\tLevels is the number of distinct colors\n',...
                    '\tLast modified location shows last edited area\n',...
                    '\tRight click on grey bubble to delete\n']);
            case 'import'
                str = sprintf(['NEURONS:\n',...
                    'Import neurons by typing in the cell ID(s)\n',...
                    'Input multiple neurons by separating their ',...
                    'IDs by commas\n',...
                    '\nCONE MOSAIC:\n',...
                    '\nIPL BOUNDARIES:\n',...
                    'Add INL-IPL and IPL-GCL Boundaries to the',...
                    'current render. Note: for now these cannot be',...
                    'updated once in place\n']);
                dlgTitle = 'Import Instructions';
            case 'scalebar'
                str = sprintf([...
                    'Add a ScaleBar through the Render Objects menu',...
                    '\nOpening dialog will ask for the XYZ ',...
                    'coordinates of the origin, the scale bar ',...
                    ' length and the units (optional)\n',...
                    '\nOnce in the figure, right click on the ',...
                    'scalebar to change properties:\n',...
                    '- ''Modify ScaleBar'' reopens the origin, bar',...
                    'size and units dialog box.\n',...
                    '- ''Text Properties'' and ''Line Properties''',...
                    ' opens the graphic object property menu where ',...
                    'you can change font size, color, width, etc\n']);
                dlgTitle = 'Scalebar Instructions';
            end
        end
    end
end
