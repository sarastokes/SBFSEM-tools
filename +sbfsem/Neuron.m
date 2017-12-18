classdef Neuron < handle
    % Analysis and graphs based only on nodes, without edges
    % 14Jun2017 - SSP - created
    % 01Aug2017 - SSP - switched createUi to separate NeuronApp class
    % 25Aug2017 - SSP - added analysis property & methods
    % 2Oct2017 - SSP - ready for odata-based import
    % 12Nov2017 - SSP - in sync with odata changes
    
    properties (SetAccess = private, GetAccess = public)
        % Cell ID in Viking
        ID
        % Volume cell exists in
        source 
        % Neuron's general attributes:
        data = struct();
        % Neuron's data from Viking
        viking
        % Table of each location ID
        nodes
        % Table of the links between annotations
        edges
        % Volume dimensions
        volumeScale
        % Attributes of each synapse
        synapses
        % Closed curve geometries
        geometries
        % Date info pulled from odata             
        lastModified 
        % Analyses related to the neuron
        analysis = containers.Map();
    end
    
    properties (Transient = true, Hidden = true)
        ODataClient
    end
    
    properties (Dependent = true, Transient = true, Hidden = true)
        somaRow % largest "cell" node's row
    end

    methods
        function obj = Neuron(ID, source, varargin)
            % NEURON  Basic cell data model
            %
            % Required inputs:
            %   ID          Cell ID number in Viking
            %   source      Volume ('i', 't', 'r')
            %
            % Optional inputs ('key', value):
            %   ct          Cell type 
            %   st          Subtype
            %   pol         Polarity: on, off, onoff
            %   prs         Inputs: LM, S, rod
            %   strata      Stratification [0 0 0 0 0]
            %   ann         Annotator
            %   notes       Any format is okay
            %
            % Use:
            %   % Import c127 in NeitzInferiorMonkey
            %   c127 = Neuron(127, 'i');
            %
            %   % Include all the neuron attributes
            %   c207 = Neuron(207, 't',...
            %       'ct', 'gc', 'st', 'smooth', 'pol', 'on',...
            %       'prs', [1 0 0], 'strata', 4, 'ann', 'SSP');
            %
            %   % Include only a few attributes
            %   c127 = Neuron(127, 'i',...
            %       'ct', 'hc', 'st', 'h2', 'ann', 'SSP');
            %   

            % Check required inputs
            validateattributes(ID, {'numeric'}, {'numel', 1});
            source = validateSource(source);
            obj.ID = ID;
            obj.source = source;
            
            % Parse additional inputs
            if nargin > 2
                obj.addDescription(varargin{:});
            end

            obj.ODataClient = sbfsem.io.NeuronOData(obj.ID, obj.source);
            
            % Fetch OData and parse
            obj.pull();

            % Track when the Neuron object was created
            obj.lastModified = datestr(now);  
        end

        function update(obj)
            % UPDATE  Reflect changes to OData
            obj.pull();
            if ~isempty(obj.geometries)
                obj.setGeometries();
            end
        end
        
        function somaRow = get.somaRow(obj)
            % This is the row associated with the largest annotation
            somaRow = find(obj.nodes.Radius == max(obj.nodes.Radius));
        end

        function synapseNames = synapseNames(obj, toChar)
            % synapseNames  Returns a list of synapse types
            if nargin < 2
                toChar = false;
            end
            synapseNames = unique(vertcat(obj.synapses.LocalName{:}));
            if toChar
                synapseNames = vertcat(arrayfun(@(x) char(x) ,synapseNames,...
                    'UniformOutput', false));
            end
        end

        function boundingBox = getBoundingBox(obj, useMicrons)
            % GETBOUNDINGBOX  Calculates extent in xy-plane 
            % INPUTS:
            %   useMicrons  [true]      microns or pixels     
            % OUTPUTS:
            %   boundingBox     [xmin ymin xmax ymax]

            if nargin < 2
                useMicrons = true;
                disp('Set units to microns');
                xyz = obj.nodes.XYZum;
                r = obj.nodes.Rum;
            else
                assert(islogical(useMicrons), 'useMicrons is t/f');
                xyz = [obj.nodes.VolumeX, obj.nodes.VolumeY];
                r = obj.nodes.Radius;
            end
            boundingBox = [min(xyz(:,1) - r), max(xyz(:,1) + r),...
                min(xyz(:,2) - r), max(xyz(:,2) + r)];  

            % Now check for closed curves
            obj.setGeometries();
            if ~isempty(obj.geometries)
                disp('Including closed curves');
                % TODO add close curve geometries
            end
        end

        function setGeometries(obj)
            % SETGEOMETRIES  Fetch closed curve OData and parse
            obj.geometries = [];
            % Make sure closed curve structures exist
            if nnz(obj.nodes.Geometry == 6) == 0
                disp('No closed curve structures detected');
                return;
            end
            fprintf('Importing geometries for %u locations\n',...
                nnz(obj.nodes.Geometry == 6));
            % Return ClosedCurve data from server
            odata = readOData([getServerName(), obj.source,...
                '/OData/Structures(', num2str(obj.ID),...
                ')\Locations?$filter=TypeCode eq 6']);
            
            for i = 1:numel(odata.value)
                obj.geometries = [obj.geometries; table(odata.value(i).ID,...
                    odata.value(i).ParentID, odata.value(i).Z,...  
                    {parseClosedCurve(odata.value(i).MosaicShape.Geometry.WellKnownText)})];
            end
            obj.geometries.Properties.VariableNames = {'ID', 'ParentID', 'Z', 'Curve'};
            % Sort by z section
            obj.geometries = sortrows(obj.geometries, 'Z', 'descend');
        end

        function synapseNodes = getSynapseNodes(obj, onlyUnique)
            % GETSYNAPSENODES  Returns a table with only synapse annotations
            % Inputs:
            %   onlyUnique      t/f  return only unique locations
            if nargin < 2
                onlyUnique = true;
            end
            if onlyUnique
                row = obj.nodes.ParentID ~= obj.ID & obj.nodes.Unique;
            else
                row = obj.nodes.ParentID ~= obj.ID;
            end
            synapseNodes = obj.nodes(row, :);

            % Sort by parentID
            synapseNodes = sortrows(synapseNodes, 'ParentID');
            synapseTable = sortrows(obj.synapses, 'ParentID');
            synapseNodes = [synapseNodes, synapseTable(:, {'N', 'LocalName'})];
        end

        function cellNodes = getCellNodes(obj)
            % GETCELLNODES  Return only cell body nodes

            row = obj.nodes.ParentID == obj.ID;
            cellNodes = obj.nodes(row, :);
        end
        
        function T = synIDs(obj, whichSyn)
            % SYNIDS  Return location IDs for synapses
            row = strcmp(obj.synapses.LocalName, whichSyn)... 
                & obj.synapses.Unique == 1;
            T = obj.synapses(row,:);
            disp(T);
        end

        function xyz = getCellXYZ(obj, useMicrons)
            % GETCELLXYZ  Returns cell body coordinates
            %   Inputs:     useMicrons  [t]  units = microns or volume
            
            if nargin < 2
                useMicrons = true;
            end
            
            row = obj.nodes.ParentID == obj.ID;
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y','Z'}};
            end
        end

        function um = getSomaSize(obj, useDiameter)
            % GETSOMASIZE  Returns soma radius in microns
            if nargin < 2
                useDiameter = false;
                disp('Returning radius');
            end

            if useDiameter
                um = max(obj.nodes.Rum) * 2;
            else
                um = max(obj.nodes.Rum);
            end
            
            % fprintf('Soma size = %.2f um diameter\n', 2*um);
        end
        
        function xyz = getSynapseXYZ(obj, syn, useMicrons)
            % GETSYNAPSEXYZ  Get xyz of synapse type
            % INPUTS:   syn             synapse name
            %           useMicrons      true/false

            if nargin < 3 % default unit is microns
                useMicrons = true;
            end
            
            % Find the synapse structures matching synapse name
            if ischar(syn)
                row = strcmp(obj.synapses.LocalName, syn);
            else
                row = vertcat(obj.synapses.LocalName{:}) == syn;                
            end
            IDs = obj.synapses.ID(row,:);

            % Find the unique instances of each synapse ID
            row = ismember(obj.nodes.ParentID, IDs) & obj.nodes.Unique;

            % get the xyz values for only those rows
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.dataTable{row, {'X','Y', 'Z'}};
            end
        end 
        
        function id = getSomaID(obj, toClipboard)
            % GETSOMAID  Get location ID for current "soma" node
            
            if nargin < 2
                toClipboard = false;
            end
            
            row = strcmp(obj.nodes.ID, obj.somaNode);
            id = obj.dataTable.LocationID(row, :);
            
            % copy to clipboard
            if toClipboard
                clipboard('copy', id);
            end
        end

        function xyz = getSomaXYZ(obj, useMicrons)
            % GETSOMAXYZ  Coordinates of soma
            if nargin < 2 % default unit is microns
                useMicrons = true;
            end

            % get the XYZ values
            if useMicrons
                xyz = obj.nodes{obj.somaRow, 'XYZum'};
            else
                xyz = obj.nodes{obj.somaRow, {'X', 'Y', 'Z'}};
            end

            if size(xyz, 1) > 1
                xyz = xyz(1,:);
            end
        end
        
        function xyz = getDAspect(obj, ax)
            % GETDASPECT  Scales a plot by x,y,z dimensions
            % Optional inputs:
            %   ax      axesHandle to apply daspect
            %
            
            xyz = obj.volumeScale/max(abs(obj.volumeScale));
            
            if nargin == 2
                assert(isa(ax, 'matlab.graphics.axis.Axes'),...
                    'Input an axes handle');
                daspect(ax, xyz);
            end
        end

        function [G, p] = graph(obj, varargin)
            % NEURON2GRAPH  Create a graph representation
            %   Inputs:
            %       directed        [f]     directed or undirected
            %       synapses        [f]     include child structures
            %       visualize       [f]     plot the graph?
            %   Outputs:
            %       G               graph or digraph
            %       p               plot handle
            %
            ip = inputParser();
            addParameter(ip, 'directed', false, @islogical);
            addParameter(ip, 'synapses', false, @islogical);
            addParameter(ip, 'visualize', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.synapses
                edge_rows = obj.edges;
            else
                edge_rows = obj.edges.ID == obj.ID;
            end

            if ip.Results.directed
                G = digraph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(num2str(obj.edges.B(edge_rows,:))));
            else
                G = graph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(num2str(obj.edges.B(edge_rows,:))));
            end

            if ip.Results.visualize
                p = plot(G);
            else
                p = [];
            end
        end

        function addDescription(obj, varargin)
            % DESCRIBE  Add neuron's description, work in progress
            ip = inputParser();
            ip.CaseSensitive = false;
            ip.addParameter('ct', [],  @(x) any(validatestring(upper(x),... 
                getCellTypes(1))));
            ip.addParameter('st', [], @ischar);
            ip.addParameter('pol', [], @(x) ischar(x) || isnumeric(x));
            ip.addParameter('prs', [], @isnumeric);
            ip.addParameter('strata', [], @isnumeric);
            ip.addParameter('ann', [], @ischar);
            ip.addParameter('notes', []);
            ip.parse(varargin{:});   

            % Check then set the neuron's properties
            obj.data.cellType = validateCellType(ip.Results.ct);
            obj.data.subtype = validateSubTypes(ip.Results.st, obj.data.cellType);
            obj.data.onoff = validatePolarity(ip.Results.pol);
            obj.data.inputs = validateConeInputs(ip.Results.prs);
            obj.data.strata = validateStrata(ip.Results.strata); 
            obj.data.annotator = ip.Results.ann;                             
            obj.data.notes = ip.Results.notes;         
        end

        function analyze(obj, DisplayName)
            % ANALYZE  Run and append an analysis
            % Inputs: 
            %   DisplayName   Analysis name

            validatestring(DisplayName,...
                {'PrimaryDendriteDiameter', 'DendriticFieldHull'});
        end
        
        function addAnalysis(obj, analysis, overwrite)
            % ADDANALYSIS  Append or update an analysis
            if nargin < 3 
                overwrite = false;
            end

            % if isempty(obj.analysis)
            %     obj.analysis = containers.Map;
            % end

            validateattributes(analysis, {'sbfsem.analysis.NeuronAnalysis'}, {});

            % Analysis holds a reference to target neuron
            if isprop(analysis, 'target') && ~isempty(analysis.target)
                analysis.target = [];
            end

            if isKey(obj.analysis, analysis.DisplayName)
                if overwrite
                    obj.analysis(analysis.DisplayName) = analysis;
                else
                    fprintf('Existing %s, call fcn w/ overwrite enabled\n',... 
                        analysis.DisplayName);
                    return;
                end
                % dialog to overwrite existing
            else
                obj.analysis(analysis.DisplayName) = analysis;
            end

            fprintf('Added %s analysis\n', analysis.DisplayName);
        end

        function saveNeuron(obj)
            % SAVENEURON  Save changes to neuron
            uisave(obj, sprintf('c%u', obj.data.cellNum));
            fprintf('Saved!\n');
        end
                 
        function printSyn(obj)
            % summarize synapses to cmd line
            [a, b] = findgroups(obj.synapses.TypeID);
            b2 = sbfsem.core.VikingStructureTypes(b);
            x = splitapply(@numel, obj.synapses.TypeID, a);
            fprintf('c%u synapses:\n', obj.ID);
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b2(ii));
            end
            fprintf('\n');
        end % printSyn
    end % methods  

    methods (Access = private)
        function pull(obj)
            % PULL  Fetch and parse neuron's OData

            % Get the relevant data with OData queries
            [obj.viking, obj.nodes, obj.edges, obj.synapses, obj.volumeScale] = ...
                obj.ODataClient.toNeuron();
            
            disp('Processing data');

            % XY transform and then convert data to microns
            obj.setXYZum();
            
            % Setup synapse columns
            obj.setupSynapses();
        end
        
        function setXYZum(obj)
            % Create an XYZ in microns column
            obj.nodes.XYZum = zeros(height(obj.nodes), 3);
            % TODO: There's an assumption about the units in here...
            obj.nodes.XYZum = bsxfun(@times,...
                [obj.nodes.VolumeX, obj.nodes.VolumeY, obj.nodes.Z],...
                (obj.volumeScale./1e3));
            % Create a column for radius in microns
            obj.nodes.Rum = obj.nodes.Radius * obj.volumeScale(1)./1000; 
        end
        
            
            

        function setupSynapses(obj)
            import sbfsem.core.StructureTypes;
            % Create a new column for "unique" synapses 
            % The purpose of this is having 1 marker per synapse structure
            obj.nodes.Unique = zeros(height(obj.nodes), 1);
            if ~isempty(obj.synapses)
                % Init temporary variables to track nodes per synapse structure
                numSynapseNodes = [];
                for i = 1:height(obj.synapses) % For each synapse structre
                    % Find the nodes associated with the synapse
                    row = find(obj.nodes.ParentID == obj.synapses.ID(i));
                    numSynapseNodes = cat(1, numSynapseNodes, numel(row));
                    % Mark unique synapses, these will be plotted
                    if numel(row) > 1
                        % Get the median annotation (along the Z-axis)
                        % TODO: decide if this is best
                        ind = find(obj.nodes.Z(row,:) == floor(median(obj.nodes.Z(row,:))));
                        obj.nodes.Unique(row(ind),:) = 1; %#ok
                    elseif numel(row) == 1
                        obj.nodes.Unique(row, :) = 1;
                    end
                end
                obj.synapses.N = numSynapseNodes;

                % Match the TypeID to the Viking StructureType
                structures = sbfsem.core.VikingStructureTypes(obj.synapses.TypeID);
                % Match to local StructureType
                localNames = cell(numel(structures),1);
                for i = 1:numel(structures)
                    localNames{i,:} = sbfsem.core.StructureTypes.fromViking(...
                        structures(i), obj.synapses.Tags{i,:});   
                end
                obj.synapses.LocalName = localNames;
                % Make sure synapses match the new naming conventions
                makeConsistent(obj);
            end                         
        end
    end
end
