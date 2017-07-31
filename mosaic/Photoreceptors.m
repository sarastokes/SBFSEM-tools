classdef Photoreceptors < Mosaic
    
    methods
        function obj = Photoreceptors(Neuron)
            if ~strcmp(Neuron.cellData.cellType, 'photoreceptor')
                error('input cellType should be a photoreceptor');
            end
            T = obj.makeRows(Neuron);
            obj.dataTable = T;
        end % constructor
        
        function T = makeRows(~, Neuron)
            % find the row matching the somaNode uuid
            row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
            % get xyzr values
            xyz = table2array(Neuron.dataTable(row, 'XYZum'));
            r = Neuron.dataTable{row, 'Size'} / 2;
            
            ribbons = nnz(strcmp(Neuron.dataTable.LocalName, 'ribbon pre') & Neuron.dataTable.Unique);
            basal = nnz(strcmp(Neuron.dataTable.LocalName, 'conv pre') & Neuron.dataTable.Unique);
            
            C = {Neuron.cellData.cellNum, Neuron.cellData.subType, ribbons, basal, xyz, r, datestr(now)};
            T = cell2table(C);
            T.Properties.VariableNames = {'CellNum', 'SubType', 'Ribbons', 'Basal','XYZ', 'Size', 'TimeStamp'};
        end % makeRows
        
        function fh = somaPlot(obj, ax)
            if nargin < 2
                fh = figure('Name', 'Cone Mosaic');
                ax = axes('Parent', fh);
            else
                ax = ax;
                fh = ax.Parent;
            end
            hold(ax, 'on');
            
            for ii = 1:size(obj.dataTable, 1)
                xyr = [obj.dataTable.XYZ(ii, 1:2) (obj.dataTable.Size(ii)/2)];
                
                % color soma by cone/rod type
                switch obj.dataTable.SubType{ii}
                    case {'lm', 'l', 'm'}
                        co = getPlotColor('l');
                    case 's'
                        co = getPlotColor('s');
                    otherwise
                        co = [0 0 0];
                end
                
                vissoma(xyr, 'ax', ax, 'co', co);
                fh.UserData = cat(2, fh.UserData, obj.dataTable.CellNum(ii));
            end
            axis equal; axis off;
        end % somaPlot
    end % methods
end % classdef