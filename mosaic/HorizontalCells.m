classdef HorizontalCells < Mosaic
    % 30Jul2017 - SSP - created
    
    properties (Constant)
        SYN = {'desmosome', 'gaba fwd', 'ribbon post'}
        VARNAME = {'Desmosome','GABA', 'Ribbon'}
    end
    
    methods
        function obj = HorizontalCells(Neuron)
            % check input cell type
            if ~strcmp(Neuron.cellData.cellType, 'horizontal cell')
                error('Neurons should be horizontal cells, not %s',...
                    Neuron.cellData.cellType);
                return;
            end
            T = obj.makeRows(Neuron);
            obj.dataTable = T;
        end % constructor
        
        function T = makeRows(obj, Neuron)
            % create row as a cell
            C = {Neuron.cellData.cellNum, Neuron.cellData.subType};
            vn = {'CellNum', 'SubType'};
            
            % synapse counts
            for ii = 1:length(obj.SYN)
                % get the number of unique synapses
                num = nnz(strcmp(Neuron.dataTable.LocalName, obj.SYN{ii}) & Neuron.dataTable.Unique);
                C = cat(2, C, num);
            end
            vn = cat(2, vn, obj.VARNAME);
            
            % find the row matching the somaNode uuid
            row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
            % get xyzr values
            xyz = table2array(Neuron.dataTable(row, 'XYZum'));
            r = Neuron.dataTable{row, 'Size'} / 2;
            C = cat(2, C, xyz, r, datestr(now));
            vn = cat(2, vn, 'XYZ', 'Size', 'TimeStamp');
            
            % make the table
            T = cell2table(C);
            T.Properties.VariableNames = vn;
        end % makeRows
    end % methods
end % classdef







