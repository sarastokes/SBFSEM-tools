classdef Neuron < handle
    % Analysis and graphs based only on nodes, without edges
    % 14Jun2017 - SSP - created
    % 01Aug2017 - SSP - switched createUi to separate NeuronApp class
    % 25Aug2017 - SSP - added analysis property & methods
    
    properties
        cellData
        analysis
        saveDir % will be used more in the future
    end
    
    properties (SetAccess = private, GetAccess = public)
        % these are properties parsed from tulip data
        skeleton % just the "cell" nodes
        dataTable % The properties included are: LocationInViking,
        % LocationID, ParentID, StructureType, Tags, ViewSize, OffEdge and
        % Terminal. See parseNodes.m for more details
        
        synData % this contains data about each synapse type in the cell
        parseDate % date .tlp or .tlpx file created
        jsonDir % filename and path for json data file
        
        networkDate % date added connectivity
        conData % connectivity data
        
        synList % synapses in cell
        somaNode % largest "cell" node
    end
    
    properties (Access = private)
        nodeList % all nodes
        tulipData
    end
    
    properties (Hidden, Transient)
        somaDist
    end
        
    methods
        function obj = Neuron(jsonData, cellNum, source, varargin)
            
            % create the cellData structure
            obj.cellData = struct();
            % create analysis map
            obj.analysis = containers.Map;
            
            % get the cell number if not provided
            if nargin < 2
                answer = inputdlg('Input the cell number:',...
                    'Cell number dialog box', 1);
                cellNum = answer{1};
                obj.cellData.cellNum = str2double(cellNum);
            else
                obj.cellData.cellNum = cellNum;
            end
            
            % get the source if not provided
            if nargin >= 3
                switch lower(source)
                    case {'temporal', 't'}
                        source = 'temporal';
                    case {'inferior', 'i'}
                        source = 'inferior';
                    case {'rc1', 'r'}
                        source = 'rc1';
                    otherwise
                        warndlg('valid source names: (temporal, t), (inferior, i), (rc1, r)');
                        source = obj.getSource();
                end
            else
                source = obj.getSource();
            end
            obj.cellData.source = source;
            
            % parse additional inputs
            ip = inputParser();
            ip.CaseSensitive = false;
            ip.addParameter('ct', [],  @(x) any(validatestring(upper(x), getCellTypes(1))));
            ip.addParameter('st', [], @ischar);
            ip.addParameter('pol', [], @(x) ischar(x) || isnumeric(x));
            ip.addParameter('prs', [], @isnumeric);
            ip.addParameter('strata', [], @isnumeric);
            ip.addParameter('ann', [], @ischar);
            ip.parse(varargin{:});
            
            % set the cellType
            obj.cellData.cellType = [];
            if ~isempty(ip.Results.ct)
                x = getCellTypes;
                ind = find(not(cellfun('isempty',...
                    strfind(getCellTypes(1), upper(ip.Results.ct))))); %#ok<STRCL1>
                obj.cellData.cellType = [x{ind}]; %#ok<FNDSB>
                fprintf('set cell type to %s\n', obj.cellData.cellType);
            end
            
            % set the subtype
            obj.cellData.subType = [];
            if ~isempty(obj.cellData.cellType) && ~isempty(ip.Results.st)
                x = getCellSubtypes(obj.cellData.cellType);
                if any(ismember(x, lower(ip.Results.st)))
                    ind = find(not(cellfun('isempty',...
                        strfind(x, lower(ip.Results.st))))); %#ok<STRCL1>
                    obj.cellData.subType = [x{ind}];  %#ok<FNDSB>
                    fprintf('set subtype to %s\n', obj.cellData.subType);
                else
                    fprintf('SubType %s not found\n', ip.Results.st);
                end
            end
            
            % set the polarity
            obj.cellData.onoff = [0 0];
            if ~isempty(ip.Results.pol)
                pol = ip.Results.pol;
                if isvector(pol) && numel(pol) == 2
                    obj.cellData.onoff = pol;
                elseif ischar(pol)
                    switch lower(pol)
                        case 'on'
                            obj.cellData.onoff(1) = 1;
                        case 'off'
                            obj.cellData.onoff(2) = 1;
                        case 'onoff'
                            obj.cellData.onoff = [1 1];
                    end
                end
            end
            
            % set the cone inputs
            obj.cellData.inputs = zeros(1,3);
            if ~isempty(ip.Results.prs)
                prs = ip.Results.prs;
                if numel(prs) == 1
                    obj.cellData.inputs(prs) = 1;
                elseif numel(prs) == 3
                    obj.cellData.inputs = prs;
                end
            end
            
            % set the strata
            obj.cellData.strata = zeros(1,5);
            if ~isempty(ip.Results.strata)
                strat = ip.Results.strata;
                if numel(strat) == 5 && max(strat) == 1
                    obj.cellData.strata = strat;
                elseif max(strat) <= 5
                    obj.cellData.strata(strat) = 1;
                end
            end
            
            % set the annotator initials
            obj.cellData.annotator = ip.Results.ann;
            
            % trigger loadCellData in NeuronApp
            if nargin > 3
                obj.cellData.flag = true;
            else
                obj.cellData.flag = false;
            end
            
            obj.cellData.notes = [];
            
            % parse the neuron
            obj.json2Neuron(jsonData, source);
            
            rows = ~strcmp(obj.dataTable.LocalName, 'cell') & obj.dataTable.Unique == 1;
            synTable = obj.dataTable(rows,:);
            [~, obj.synList] = findgroups(synTable.LocalName);            
        end % constructor
        
        function update(obj, jsonData)
            obj.json2Neuron(jsonData, obj.cellData.source);
            obj.parseDate = datestr(now);
            fprintf('updated underlying data\n');
        end % update data
        
        function T = synIDs(obj, whichSyn)
            % SYNIDS  Return location IDs for synapses
            rows = strcmp(obj.dataTable.LocalName, whichSyn) & obj.dataTable.Unique == 1;
            T = obj.dataTable(rows,:);
            disp(T);
        end % synIDs
        
        function xyz = getSynapseXYZ(obj, syn, micronFlag)
            % GETSYNAPSEXYZ  Get xyz of synapse type
            % INPUTS:   syn             synapse name
            %           microns         true/false

            if nargin < 3 % default unit is microns
                micronFlag = true;
            end

            % check that input syn is in synapse list
            syn = validatestring(syn, obj.synList);

            % find unique rows with synapse name
            rows = strcmp(obj.dataTable.LocalName, syn)... 
                & obj.dataTable.Unique == 1;

            % get the xyz values for only those rows
            if micronFlag
                xyz = obj.dataTable{rows, 'XYZum'};
            else
                xyz = obj.dataTable{rows, 'XYZ'};
            end
        end % getSynapseXYZ


        function fh = openApp(obj)
            fh = NeuronApp(obj);
        end
        
        function id = getSomaID(obj, toClipboard)
            % GETSOMAID  Get location ID for current "soma" node
            
            if nargin < 2
                toClipboard = false;
            end
            
            row = strcmp(obj.dataTable.UUID, obj.somaNode);
            id = obj.dataTable.LocationID(row, :);
            
            % copy to clipboard
            if toClipboard
                clipboard('copy', id);
            end
        end

        function xyz = getSomaXYZ(obj, micronFlag)
            % GETSOMAXYZ  Coordinates of soma
            if nargin < 2 % default unit is microns
                micronFlag = true;
            end
            % find the row matching the soma node uuid
            row = strcmp(obj.dataTable.UUID, obj.somaNode);
            % get the XYZ values
            if micronFlag
                xyz = table2array(obj.dataTable(row, 'XYZum'));
            else
                xyz = table2array(obj.dataTable(row, 'XYZ'));
            end
        end % getSomaXYZ
        
        function addAnalysis(obj, analysis, overwrite)
            % ADDANALYSIS  Append or update an analysis
            if nargin < 3 
                overwrite = false;
            end
            if isempty(obj.analysis)
                obj.analysis = containers.Map;
            end
            validateattributes(analysis, {'NeuronAnalysis'}, {});
            if isKey(obj.analysis, analysis.keyName)
                if overwrite
                    obj.analysis(analysis.keyName) = analysis;
                else
                    fprintf('Existing %s, call fcn w/ overwrite enabled\n',... 
                        analysis.keyName);
                    return;
                end
                % dialog to overwrite existing
            else
                obj.analysis(analysis.keyName) = analysis;
            end
            fprintf('Added %s analysis\n', analysis.keyName);
        end % addanalysis

        function saveNeuron(obj)
            % SAVENEURON  Save changes to neuron
            uisave(obj, sprintf('c%u', obj.cellData.cellNum));
            fprintf('Saved!\n');
        end
                 
        function printSyn(obj)
            % summarize synapses to cmd line
            rows = ~strcmp(obj.dataTable.LocalName, 'cell') & obj.dataTable.Unique;
            T = obj.dataTable(rows,:);
            
            [a, b] = findgroups(T.LocalName);
            x = splitapply(@numel, T.LocalName, a);
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b{ii});
            end
        end % printSyn

        function rescaleXYZ(obj)
            % RESCALEXYZ  Change XYZ based on OData scale
            dbase = getODataURL(obj.cellData.source);
            vol = webread([dbase '/Scale'],... 
                'Timeout', 30,...
                'ContentType', 'json',...
                'CharacterEncoding', 'UTF-8');
            newScale = [vol.X.Value, vol.Y.Value, vol.Z.Value];
            fprintf('Updating XYZum with scale:\n    %.2g, %.2g, %.2g in %s\n',...
                newScale, vol.X.Units);
            % convert to microns if needed
            if strcmp(vol.X.Units, 'nm') && strcmp(vol.X.Units, 'nm')
                newScale = newScale ./ 1000; %#ok<NASGU>
            end
            obj.dataTable.XYZum = bsxfun(@times, obj.dataTable.XYZ,... 
                [vol.X.Value, vol.Y.Value, vol.Z.Value]);
        end
    end % methods
    
    methods % network methods
        function addNetwork(obj, networkFile)
            % ADDCONNECTIVITY  Add network data to neuron
            if nargin < 2
                [fileName, filePath] = uigetfile('*.json', 'Pick a network:');
                obj.conData = parseConnectivity([fileName, filePath]);
            else % json file name in current directory
                obj.conData = parseConnectivity(networkFile);
            end
            obj.networkDate = datestr(now);
            fprintf('added network\n');
        end % addNetwork
    end % network methods
    
    methods (Access = private)     
        function source = getSource(obj) %#ok<MANU>
            % GETSOURCE  Dialog box for tissue block
            answer = questdlg('Which block?',...
                'tissue source dialog',...
                'inferior', 'temporal', 'rc1', 'inferior');
            source = answer;
        end % getSource
        
        function json2Neuron(obj, jsonData, source)
            % JSON2NEURON  Wrapper for loadjson
            % detect input type
            if ischar(jsonData) && strcmp(jsonData(end-3:end), 'json')
                fprintf('parsing with loadjson.m...');
                jsonData = loadjson(jsonData);
                fprintf('parsed\n');
                jsonData = parseNeuron(jsonData, source);
                obj.dataTable = jsonData.dataTable;
            elseif isstruct(jsonData) && isfield(jsonData, 'version')
                jsonData = parseNeuron(jsonData, source);
            elseif isstruct(jsonData) && isfield(jsonData, 'somaNode')
                fprintf('already parsed from parseNodes.m\n');
            else % could also supply output from loadjson..
                warndlg('input filename as string or struct from loadjson()');
                return
            end
            
            obj.parseDate = jsonData.parseDate;
            
            obj.nodeList = jsonData.nodeList;
            
            obj.synData = jsonData.typeData;
            obj.tulipData = jsonData.tulipData;
            
            obj.skeleton = jsonData.skeleton;
            obj.somaNode = jsonData.somaNode;
        end % json2neuron     
    end % methods private
end % classdef
