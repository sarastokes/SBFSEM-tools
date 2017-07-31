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
            % add a neuron not currently in workspace
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
                load(n);
                obj.add(newNeuron);
                fprint('loadadd successful! added %u\n',...
                    newNeuron.cellData.cellNum);
            catch
                fprintf('No file or directory:\n%s\n', n);
            end
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
            obj.dataTable(rowNum,:) = [];
        end % rmRow
        
        function obj = rmNeuron(obj, cellNum)
            row = obj.dataTable.CellNum == cellNum;
            if ~isempty(row)
                obj.dataTable(row,:) = [];
            else
                warndlg('cell %u not found in Mosaic', cellNum);
            end
        end % rmNeuron
        
        function obj = describe(obj, str)
            obj.dataTable.Properties.Description = str;
        end
        
        function disp(obj)
            if ~isempty(obj.dataTable.Properties.Description)
                disp(obj.dataTable.Properties.Description);
            end
            disp(obj.dataTable);
        end % disp
        
        function obj = sortrows(obj)
            obj.dataTable = sortrows(obj.dataTable);
        end % sortrows
        
        function T = table(obj)
            % ditch the mosaic class
            T = obj.dataTable;
        end % table
        
        function [ind, dst] = nearestNeighbor(obj, rowNum)
            if nargin == 2
                xyz = obj.dataTable.XYZ(rowNum, :);
            else
                xyz = obj.dataTable.XYZ;
            end
            [ind, dst] = knnsearch(xyz(1), xyz(2), 'K', 3);
        end % nearestNeighbor
        
        function somaPlot(obj, varargin)
            ip = inputParser();
            ip.addParameter('co', [0 0 0], @isnumeric);
            ip.addParameter('ax', [], @ishandle);
            ip.parse(varargin{:});
            if isempty(ip.Results.ax)
                fh = figure('Name', 'Soma Mosaic');
                ax = axes('Parent', fh);
            else
                ax = ip.Results.ax;
                fh = ax.Parent;
            end
            hold(ax, 'on');
            for ii = 1:size(obj.dataTable, 1)
                xyr = [obj.dataTable.XYZ(ii, 1:2) (obj.dataTable.Size(ii)/2)];
                vissoma(xyr, 'ax', ax, 'co', ip.Results.co);
                fh.UserData = cat(2, fh.UserData, obj.dataTable.CellNum(ii));
            end
            axis equal; axis off;
        end % somaPlot
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