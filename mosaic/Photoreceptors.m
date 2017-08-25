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
            ip = inputParser();
            ip.addParameter('ax', [], @ishandle);
            ip.addParameter('lw', 1, @isnumeric);
            ip.addParameter('lbl', false, @islogical);
            ip.addParameter('onlyCones', false, @islogical);
            
            ip.parse(varargin{:});
            if isempty(ip.Results.ax);
                fh = figure('Name', 'Cone Mosaic');
                ax = axes('Parent', fh);
            else
                ax = ip.Results.ax;
                fh = ax.Parent;
            end
            hold(ax, 'on');
            
            if ip.Results.onlyCones
                rows = ~strcmp(obj.dataTable.SubType, 'rod');
                T = obj.dataTable(rows,:);
            else
                T = obj.dataTable;
            end
            
            for ii = 1:size(T, 1)
                xyr = [T.XYZ(ii, 1:2) (T.Size(ii)/2)];               
                % color soma by cone/rod type
                switch T.SubType{ii}
                    case {'lm', 'l', 'm'}
                        co = getPlotColor('l');
                    case 's'
                        co = getPlotColor('s');
                    otherwise
                        co = [0 0 0];
                end                
                vissoma(xyr, 'ax', ax, 'co', co, 'lw', ip.Results.lw);
                fh.UserData = cat(2, fh.UserData, T.CellNum(ii));
                if ip.Results.lbl
                    lbl = num2str(T.CellNum(ii));
                    text(xyr(1)-(xyr(3)/2), xyr(2), xyr(3), lbl, 'FontSize', 8);
                end
            end
            axis equal;
            set(ax, 'XColor', 'w', 'YColor', 'w');
        end % somaPlot
    end % methods
end % classdef