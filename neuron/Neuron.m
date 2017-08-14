classdef Neuron < handle
    % Analysis and graphs based only on nodes, without edges
    % 14Jun2017 - SSP - created
    % 01Aug2017 - SSP - switched createUi to separate NeuronApp class
    
    properties
        cellData
        saveDir
    end
    
    properties (SetAccess = private, GetAccess = public)
        % these are properties parsed from tulip data
        skeleton % just the "cell" nodes
        dataTable % The properties included are: LocationInViking,
        % LocationID, ParentID, StructureType, Tags, ViewSize, OffEdge and
        % Terminal. See parseNodes.m for more details
        
        synData % this contains data about each synapse type in the cell
        parseDate % date .tlp or .tlpx file created
        analysisDate % date run thru NeuronNodes
        
        connectivityDate % date added connectivity
        conData % connectivity data
        
        synList
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
                % first check abbreviated types
                % {'--', 'GC', 'BC', 'HC', 'AC','PR', 'IPC'};
                x = getCellTypes;
                ind = find(not(cellfun('isempty',...
                    strfind(getCellTypes(1), upper(ip.Results.ct)))));
                obj.cellData.cellType = [x{ind}]; %#ok<FNDSB>
                fprintf('set cell type to %s\n', obj.cellData.cellType);
            end
            
            % set the subtype
            obj.cellData.subType = [];
            if ~isempty(obj.cellData.cellType) && ~isempty(ip.Results.st)
                x = getCellSubtypes(obj.cellData.cellType);
                if any(ismember(x, lower(ip.Results.st)));
                    ind = find(not(cellfun('isempty',...
                        strfind(x, lower(ip.Results.st)))));
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
        
        function updateData(obj, jsonData)
            obj.json2Neuron(jsonData, obj.cellData.source);
            obj.analysisDate = datestr(now);
            fprintf('updated underlying data\n');
        end % update data
        
        function addConnectivity(obj, connectivityFile)
            % add something to check for overwrite?
            if ischar(connectivityFile)
                obj.conData = parseConnectivity(connectivityFile);
            elseif isstruct(connectivityFile)
                obj.conData = connectivityFile;
            end
            obj.connectivityDate = datestr(now);
            fprintf('added connectivity\n');
        end % addConnectivity
        
        function T = synIDs(obj, whichSyn)
            % SYNIDS  Return location IDs for synapses
            rows = strcmp(obj.dataTable.LocalName, whichSyn) & obj.dataTable.Unique == 1;
            T = obj.dataTable(rows,:);
            disp(T);
        end % synIDs
        
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
    end % methods
    
    
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
            obj.analysisDate = datestr(now);
            
            obj.nodeList = jsonData.nodeList;
            
            obj.synData = jsonData.typeData;
            obj.tulipData = jsonData.tulipData;
            
            obj.skeleton = jsonData.skeleton;
            obj.somaNode = jsonData.somaNode;
        end % json2neuron
        
    end % methods private
    
end % classdef
