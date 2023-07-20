classdef LightConfig < handle 
    % LightConfig   A class to configure lights in the scene
    %
    % History:
    %   26Apr2023 - SSP
    % ----------------------------------------------------------------------

    properties
        Parent
        Figure
        Table
    end

    properties (Constant)
        ICON_DIR = [fileparts(mfilename('fullname')), filesep, 'icons'];
        CACHE = [fileparts(fileparts(mfilename('fullname'))), filesep, 'data'];
    end

    methods
        function obj = LightConfig(parent)
            obj.Parent = parent;
            disp(fileparts(mfilename('fullname')))
            obj.createUi();
        end
    end

    methods
        function onAddLight(obj, ~, ~)
            newLight = light(obj.Parent.ax);
            lightangle(newLight, 0, 0);
            obj.Parent.lights = cat(2, obj.Parent.lights, newLight);
            T = obj.getLightTable();
            obj.Table.Data = T;
        end

        function onRemoveLight(obj, ~, ~)
            if isempty(obj.Table.Data)
                return
            end

            idx = obj.Table.Selection;
            if isempty(idx)
                errordlg('Select the row you want to delete.', 'Selection Error');
                return
            end
            obj.Parent.lights(idx(1)) = [];
            T = obj.getLightTable();
            obj.Table.Data = T;
        end

        function onCellEdit(obj, src, evt)
            if evt.Indices(2) == 1
                obj.Parent.lights(evt.Indices(1)).Visible = ...
                    matlab.lang.OnOffSwitchState(src.Data{evt.Indices(1), evt.Indices(2)});
                if ~all(obj.Table.Data{:,1})
                    value = 0;
                else
                    value = 1;
                end
                set(findobj(obj.Parent, 'Tag', 'ToggleLights'),...
                    'Value', value);
            else
                value = src.Data{evt.Indices(1), 2:3};
                lightangle(obj.Parent.lights(evt.Indices(1)),...
                    value(1), value(2));
            end
        end
    end

    methods 
        function createUi(obj)
            obj.Figure = uifigure();
            obj.Figure.Position(3:4) = obj.Figure.Position(3:4)/2;
            mainLayout = uigridlayout(obj.Figure, [2, 2],...
                "RowHeight", {"1x", 30});
            T = obj.getLightTable();
            
            obj.Table = uitable(mainLayout, 'Data', T,... 
                'ColumnEditable', true,...
                'CellEditCallback', @obj.onCellEdit);
            obj.Table.Layout.Column = [1 2];

            
            uibutton(mainLayout,...
                "Text", "Add Light",...
                "Icon", fullfile(fileparts(mfilename("fullname")), 'icons', 'add.png'),...
                "ButtonPushedFcn", @obj.onAddLight);
            uibutton(mainLayout,...
                "Text", "Remove Light",...
                "Icon", fullfile(fileparts(mfilename("fullname")), 'icons', 'do-not-disturb.png'),...
                "ButtonPushedFcn", @obj.onRemoveLight);
        end

        function T = getLightTable(obj)
            lights = obj.Parent.lights;
            isShown = arrayfun(@(x) logical(x.Visible), lights);
            azimuth = zeros(numel(lights), 1); 
            elevation = zeros(numel(lights), 1);
            for i = 1:numel(lights)
                [azimuth(i), elevation(i)] = lightangle(lights(i));
            end
            T = table(isShown', azimuth, elevation,...
                'VariableNames', {'Toggle', 'Azimuth', 'Elevation'});
        end
    end
end 