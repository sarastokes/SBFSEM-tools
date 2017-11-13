classdef Photoreceptors < Mosaic
    % 30Jul2017 - SSP - created
    
    methods
        function obj = Photoreceptors(Neuron, H2input)
            if ~strcmp(Neuron.cellData.cellType, 'photoreceptor')
                error('input cellType should be a photoreceptor');
            end
            
            if nargin <2
                H2input = 0;
            end
            
            T = obj.makeRows(Neuron, H2input);
            obj.dataTable = T;
        end % constructor
        
        function obj = setH2Input(obj, cellNum, flag)
            % SETH2INPUT  Set whether the cone receives H2 input
            if ~ismember(flag, [0 1])
                warndlg('H2 input should be set to 0 (no) or 1 (yes)');
                return;
            end
            row = obj.dataTable.CellNum == cellNum;
            if nnz(row) == 1
                obj.dataTable.H2Input(row,:) = flag;
            end
        end % setH2Input
        
        function obj = addTracing(obj, cellNum, mat)
            % ADDTRACING  Add outline of cone
            row = obj.dataTable.CellNum == cellNum;
            if nnz(row) == 1
                obj.dataTable.Tracing(row,:) = mat;
            end
        end % addTracing
        
        function add(obj, Neuron, varargin)
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
            ip = inputParser();
            ip.addParameter('h2', 0, @isnumeric);
            ip.parse(varargin{:});
            
            T = obj.makeRows(Neuron, ip.Results.h2);
            obj.dataTable = [obj.dataTable; T];
            obj.sortrows();
        end % add
        
        function T = makeRows(~, Neuron, H2input)
            % find the row matching the somaNode uuid
            row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
            % get xyzr values
            xyz = table2array(Neuron.dataTable(row, 'XYZum'));
            r = Neuron.dataTable{row, 'Size'} / 2;
            
            ribbons = nnz(strcmp(Neuron.dataTable.LocalName, 'ribbon pre')...
                & Neuron.dataTable.Unique);
            basal = nnz(strcmp(Neuron.dataTable.LocalName, 'conv pre')...
                & Neuron.dataTable.Unique);
            
            C = {Neuron.cellData.cellNum, Neuron.cellData.subType,...
                ribbons, basal, xyz, r, datestr(now), H2input};
            T = cell2table(C);
            T.Properties.VariableNames = {'CellNum', 'SubType',...
                'Ribbons', 'Basal','XYZ', 'Size', 'TimeStamp',...
                'H2Input'};
        end % makeRows
        
        function fh = somaPlot(obj, varargin)
            % SOMAPLOT  Process cones/rods, colors before passing to Mosaic
            % INPUTS: all the Mosaic somaPlot inputs
            %   onlyCones     [false]  skip the rods
            
            ip = inputParser();
            ip.KeepUnmatched = true;
            ip.CaseSensitive = false;
            addParameter(ip, 'onlyCones', false, @islogical);
            parse(ip, varargin{:});
            extras = ip.Unmatched;
            
            if ip.Results.onlyCones
                rows = ~strcmp(obj.dataTable.SubType, 'rod');
                T = obj.dataTable(rows,:);
            else
                T = obj.dataTable;
            end
            
            % assign colors by cone type
            if ~isfield(extras, 'co')
                extras.co = zeros(height(T), 3);
                for ii = 1:height(T)
                    switch T.SubType{ii}
                        case {'lm', 'l', 'm'}
                            extras.co(ii,:) = getPlotColor('l');
                        case 's'
                            extras.co(ii,:) = getPlotColor('s');
                        otherwise
                            extras.co(ii,:) = [0.4 0.4 0.4];
                    end
                end
            end 
            extras.T = T;
            fh = somaPlot@Mosaic(obj, extras);
        end % somaPlot
    end % methods
end % classdef
