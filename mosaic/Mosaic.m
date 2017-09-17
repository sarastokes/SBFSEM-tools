classdef Mosaic < handle
    % essentially matlab's table class
    % apparently table can't be subclassed (?)
    %
    % 29Jul2017 - SSP - created

    properties
        dataTable
    end

    methods
        function obj = Mosaic()
        end % constructor

        function obj = loadadd(obj, fname, fpath)
            % LOADADD  Add a neuron not currently in workspace
            % fname can be 'c207.mat' or 207
            if nargin < 3
                % fprintf('Set to default folder: NeitzInferior\n');
                fpath = [getFilepaths('data'), filesep, 'NeitzInferior'];
            end

            if isnumeric(fname)
                n = sprintf('c%u.mat', fname);
            else
                n = fname;
            end

            n = [fpath filesep n];

            try
                newNeuron = load(n);
            catch
                fprintf('No file or directory:\n%s\n', n);
                return;
            end

            f = fieldnames(newNeuron);
            obj.add(newNeuron.(f{1}));

            fprintf('loadadd successful! added %u\n',...
                newNeuron.(f{1}).cellData.cellNum);
        end

        function obj = add(obj, Neuron)
            % make sure Neuron isn't already in table
            if ~isempty(find(obj.dataTable.CellNum == Neuron.cellData.cellNum)) %#ok<EFIND>
                selection = questdlg('Overwrite existing cell row?',...
                    'Neuron overwrite dialog',...
                    {'Yes', 'No', 'Yes'});
                if strcmp(selection, 'No')
                    return;
                end
                row = obj.dataTable.CellNum == Neuron.cellData.cellNum;
                obj.dataTable(row, :)=[];
            end
            T = obj.makeRows(Neuron);
            obj.dataTable = [obj.dataTable; T];
            obj.sortrows();
        end % add

        function obj = update(obj, Neuron)
            % add function but with permission to overwrite
            % TODO: less code repetition
            if isempty(find(obj.dataTable.CellNum == Neuron.cellData.cellNum)) %#ok<EFIND>
                fprintf('Neuron not in Mosaic, use add()\n');
                return;
            end
            % delete the existing row
            row = obj.dataTable.CellNum == Neuron.cellData.cellNum;
            obj.dataTable(row,:) = [];
            % add the updated new row
            T = obj.makeRows(Neuron);
            obj.dataTable = [obj.dataTable; T];
            obj.sortrows();
        end

        function obj = rmRow(obj, rowNum)
            % RMROW  Remove neuron by row number
            obj.dataTable(rowNum,:) = [];
        end % rmRow

        function obj = rmNeuron(obj, cellNum)
            % RMNEURON  Remove neuron by cell number
            row = obj.dataTable.CellNum == cellNum;
            if ~isempty(row)
                obj.dataTable(row,:) = [];
            else
                warndlg('cell %u not found in Mosaic', cellNum);
            end
        end % rmNeuron

        function rmCol(obj, colName)
            % RMCOL  Remove a column from mosaic
            if ischar(colName)
                ind = find(ismember(obj.dataTable.Properties.VariableNames,...
                    colName));
            else
                ind = colName;
            end

            obj.dataTable(:,ind) = [];
        end % rmCol

        function obj = describe(obj, str)
            % DESCRIBE  Edit description
            obj.dataTable.Properties.Description = str;
        end

        function disp(obj)
            % DISP  Display table, description if exists
            if ~isempty(obj.dataTable.Properties.Description)
                disp(obj.dataTable.Properties.Description);
            end
            disp(obj.dataTable);
        end % disp

        function obj = sortrows(obj)
            % SORTROWS  Sorts rows by CellNum
            obj.dataTable = sortrows(obj.dataTable);
        end % sortrows

        function T = table(obj)
            % TABLE  Ditches the mosaic class
            T = obj.dataTable;
        end % table

        function newMosaic = split(key, value)
            % SPLIT  Make a new mosaic from a subset
            newMosaic = obj;
            if isa(value, 'char')
                rows = strcmp(newMosaic.dataTable.(key), value);
            elseif isa(value, 'double')
                rows = newMosaic.dataTable.(key) == value;
            end

            newMosaic.rmRows(rows);
        end

        function [ind, dst] = nearestNeighbor(obj, varargin)
            % NEARESTNEIGHBOR  Runs knnsearch with option to plot result
            ip = inputParser();
            ip.addParameter('rowNum', [], @isvector);
            ip.addParameter('k', 3, @isnumeric);
            ip.addParameter('graph', false, @islogical);
            ip.parse(varargin{:});
            rowNum = ip.Results.rowNum;
            K = ip.Results.k;

            if isempty(rowNum);
                xyz = obj.dataTable.XYZ(rowNum, 1:2);
                lbl = obj.dataTable.CellNum(rowNum);
            else
                xyz = obj.dataTable.XYZ(:, 1:2);
                lbl = obj.dataTable.CellNum;
            end
            [ind, dst] = knnsearch(xyz, xyz, 'K', K);
            if ip.Results.graph
                figure('Name', 'knnsearch result');
                barh(dst(:,2:K), 'stacked');
                set(gca, 'YTickLabel', lbl, 'Box', 'off');
            end
        end % nearestNeighbor

        function fh = somaPlot(obj, varargin)
            % SOMAPLOT  Plots somas of cells in mosaic
            ip = inputParser();
            addParameter(ip, 'T', obj.dataTable, @istable);
            addParameter(ip, 'co', [0.4 0.4 0.4], @ismatrix);
            addParameter(ip, 'ax', [], @ishandle);
            addParameter(ip, 'lbl', false, @islogical);
            addParameter(ip, 'lw', 1, @isnumeric);
            parse(ip, varargin{:});
            T = ip.Results.T;

            if isempty(ip.Results.ax)
                fh = figure('Name', 'Soma Mosaic');
                ax = axes('Parent', fh);
            else
                ax = ip.Results.ax;
                fh = ax.Parent;
            end
            hold(ax, 'on');

            if size(ip.Results.co, 2) == 3
                if size(ip.Results.co,1) == 1
                    co = repmat(ip.Results.co, size(T, 1), 1);
                elseif size(ip.Results.co, 1) == height(T)
                    co = ip.Results.co;
                else
                    warndlg('co should be a 1x3 RGB vector or an Nx3 matrix where N = number of neurons in table');
                    co = repmat([0.4 0.4 0.4], [height(T) 1]);
                end
            else
                warndlg('co should be a 1x3 RGB vector or an Nx3 matrix where N = number of neurons in table');
                co = repmat([0.4 0.4 0.4], [height(T) 1]);
            end

            for ii = 1:height(T)
                xyr = [T.XYZ(ii, 1:2) (T.Size(ii)/2)];
                vissoma(xyr, 'ax', ax,...
                    'co', co(ii,:), 'lw', ip.Results.lw);
                fh.UserData = cat(2, fh.UserData, T.CellNum(ii));
                if ip.Results.lbl
                    lbl = ['c' num2str(T.CellNum(ii))];
                    text(xyr(1), xyr(2), xyr(3), lbl);
                end
            end

            axis equal;
            set(gca, 'XColor', 'w', 'YColor', 'w');
        end % somaPlot

        function obj = addField(obj, varName, varType)
            % ADDFIELD  Add a new column to an existing mosaic
            if isa(varType, 'char')
                T = cell(size(obj.dataTable, 1), 1);
            else
                T = zeros(size(obj.dataTable, 1), 1);
            end
            T = array2table(T);
            T.Properties.VariableNames = {varName};
            obj.dataTable = [obj.dataTable, T];
        end % addField
    end % methods

    methods (Static)
        function str = polStr(Neuron)
            if nnz(Neuron.cellData.onoff) == 2
                str = 'onoff';
            elseif nnz(Neuron.cellData.onoff) == 0
                str = '-';
            elseif Neuron.cellData.onoff(1) == 1
                str = 'on';
            else
                str = 'off';
            end
        end

        function str = coneStr(Neuron)
            coneInputs = Neuron.cellData.inputs;
            % input cellData.inputs
            switch nnz(coneInputs)
                case 0
                    str = '-';
                case 1
                    if coneInputs(1) == 1
                        str = 'lm';
                    elseif coneInputs(2) == 1
                        str = 's';
                    elseif coneInputs(3) == 1
                        str = 'rod';
                    end
                case 2
                    str = 'lms';
                case 3
                    str = 'all';
            end
        end % coneStr

        function str = cellNameStr(Neuron)
            if ~isempty(Neuron.cellData.cellType)
                if isempty(Neuron.cellData.subType)
                    str = Neuron.cellData.cellType;
                else
                    str = [Neuron.cellData.subType, ' ', Neuron.cellData.cellType];
                end
            else
                str = '-';
            end
        end % cellNameStr
    end % methods static
end % classdef
