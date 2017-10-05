classdef Neuron < handle
    % Analysis and graphs based only on nodes, without edges
    % 14Jun2017 - SSP - created
    % 01Aug2017 - SSP - switched createUi to separate NeuronApp class
    % 25Aug2017 - SSP - added analysis property & methods
    % 2Oct2017 - SSP - ready for odata-based import
    
    properties
        cellData
        analysis = containers.Map()
        saveDir % will be used more in the future
    end
    
    properties % new
        neuronData
        nodeData
        edgeData
        childData
    end
    
    properties (SetAccess = private, GetAccess = public)
        parseDate % date info pulled from odata        
        networkDate % date added connectivity
        conData % connectivity data        
    end
    
    properties (Dependent = true)
        synList % synapses in cell
        somaRow % largest "cell" node's row
    end

    methods
        function obj = Neuron(ID, source, varargin)
            validateattributes(ID, {'numeric'}, {'numel', 1});
            source = validatestring(source, {'temporal', 'inferior', 'rc1'});
            
            % Get the OData
            [obj.neuronData, obj.nodeData, obj.edgeData, obj.childData] =... 
                getNeuronOData(ID, source);
            
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
            obj.cellData.cellType = validateCellType(ip.Results.ct);
      
            % set the subtype
            obj.cellData.subtype = validateSubType(ip.Results.st, obj.cellData.cellType);
            
            obj.cellData.onoff = validatePolarity(ip.Results.pol);
            obj.cellData.inputs = validateConeInputs(ip.Results.prs);
            obj.cellData.strata = validateStrata(ip.Results.strata);
            
            obj.cellData.annotator = ip.Results.ann;        
            
            % trigger loadCellData in NeuronApp
            if nargin > 3
                obj.cellData.flag = true;
            else
                obj.cellData.flag = false;
            end
            
            obj.cellData.notes = [];
            
            obj.nodeData.Unique = zeros(height(obj.nodeData), 1);
            localNames = []; nChild = [];
            for i = 1:height(obj.childData)
                localNames = cat(2, localNames, getLocalSynapseName(...
                    obj.childData.TypeID(i,:), obj.childData.Tags(i,:)));
                row = find(obj.nodeData.ParentID == obj.childData.ID(i));
                nChild = cat(2, row, numel(ind));
                if numel(ind) > 1
                    ind = find(b.Z(row,:) == median(b.Z(row,:)));
                    obj.nodeData.Unique(row(ind)) = 1;
                end
            end
            obj.childData.LocalName = localNames;
            obj.childData.N = nChild;
            
            obj.parseDate = datestr(now);
           
        end % constructor
        
        function somaRow = get.somaRow(obj)
            somaRow = find(obj.nodeData.Radius == max(obj.nodeData.Radius));
        end

        function synList = get.synList(obj)
            [~, obj.synList] = findgroups(obj.childData.LocalName);
        end
        
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
            rows = ~strcmp(obj.childData.LocalName, 'cell');
            T = obj.childData(rows,:);
            
            [a, b] = findgroups(T.LocalName);
            x = splitapply(@numel, T.LocalName, a);
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b{ii});
            end
        end % printSyn

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
    end % methods  
end % classdef
