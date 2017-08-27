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

        function fh = somaPlot(obj, varargin)
          % SOMAPLOT  Plot somas sorted by h1 or h2
          ip = inputParser();
          ip.KeepUnmatched = true;
          ip.CaseSensitive = false;
          addParameter(ip, 'hcType', '',...
            @(x) any(validatestring(lower(x), {'h1', 'h2'})));
          parse(ip, varargin{:})
          extras = ip.Unmatched;


          if ~isempty(ip.Results.hcType)
            row = strcmp(obj.dataTable.SubType, ip.Results.hcType);
            extras.T = obj.dataTable(row, :);
          else
            extras.T = obj.dataTable;
          end

          if ~isfield(extras, 'co')
            extras.co = obj.assignColors(extras.T);
          end

          fh = somaPlot@Mosaic(obj, extras);
        end % somaPlot

        function colorVec = assignColors(obj, T)
            % ASSIGNCOLORS  Get a matrix of plot colors by hc subtype

            if nargin < 2
              T = obj.dataTable;
            end

            colorVec = zeros(height(T), 3);
            for ii = 1:height(T)
                switch lower(T.SubType{ii})
                    case 'h1'
                        colorVec(ii, :) = rgb('light orange');
                    case 'h2'
                        colorVec(ii, :) = rgb('teal');
                    otherwise
                        colorVec(ii, :) = [0.4 0.4 0.4];
                end
            end
        end % assignColors
    end % methods
end % classdef
