classdef ConeOutline < handle
    % CONEOUTLINE
    %
    % 30Dec2017
    % --
    
    properties (SetAccess = private, GetAccess = public)
        closedCurve
        coneTrace
    end
    
    properties (Constant = true, Hidden = true)
        TAG_DEFAULT = 'cone';
    end
    
    methods
        function obj = ConeOutline(neuron, varargin)
            tagStr = obj.TAG_DEFAULT;
            if isinteger(neuron)
                % Only NeitzInferiorMonkey would have cone outlines
                neuron = Neuron(neuron, 'i');
            end
            if isa(neuron, 'sbfsem.core.StructureAPI')
                if isempty(neuron.geometries)
                    neuron.getGeometries();
                end
                T = neuron.geometries;
                tagStr = ['c', num2str(neuron.ID)];
            end
            
            if istable(neuron)
                T = neuron;
            end
            
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'Z', [], @isinteger);
            addParameter(ip, 'nDim', 3,...
                @(x) ismember(x, [2 3]));
            addParameter(ip, 'ax', [], @ishandle);
            % Patch specifications:
            addParameter(ip, 'FaceColor', 'none',...
                @(x) isvector(x) || ischar(x));
            addParameter(ip, 'EdgeColor', [0 0 0],...
                @(x) isvector(x) || ischar(x));
            addParameter('FaceAlpha', 1, @isnumeric);
            addParameter(ip, 'LineWidth', 1, @isnumeric);
            addParameter(ip, 'Tag', tagStr, @ischar);
            parse(ip, varargin{:});
            
            Z = ip.Results.Z;
            if height(T) > 1
                if isempty(Z)
                    warning('Multiple closed curve sections');
                    return;
                else
                    T = T(T.Z == Z);
                end
            end
            
            obj.closedCurve = sbfsem.builtin.ClosedCurve(T);
            
            if isempty(ip.Results.ax)
                fh = figure();
                ax = axes('Parent', fh);
            else
                ax = ip.Results.ax;
            end
            
            pts = cat(1, obj.closedCurve.outline,...
                obj.closedCurve.outline(end-2:end,:));
            
            [x, y] = catmullRomSpline(pts(:,1), pts(:,2));
            
            if ip.Results.nDim == 2
                obj.coneTrace = patch(x, y, 'Parent', ax);
            else
                obj.coneTrace = patch(x, y, z, 'Parent', ax);
            end
            
            set(obj.coneTrace,...
                'FaceColor', ip.Results.FaceColor,...
                'EdgeColor', ip.Results.EdgeColor,...
                'FaceAlpha', ip.Results.FaceAlpha,...
                'FaceLighting', 'none',...
                'EdgeLighting', 'none',...
                'LineWidth', ip.Results.LineWidth,...
                'Tag', ip.Results.Tag);

            obj.createContextMenu(obj.coneTrace);
        end
    end
    
    methods (Access = private)
        function createContextMenu(obj, h)
            % Input:
            %	h 		parent graphics object handle
            cmenu = uicontextmenu;
            
            uimenu(cmenu,...
                'Label', 'Export DAE',...
                'Callback', @obj.onExportDAE);
            uimenu(cmenu,...
                'Label', sprintf('Tag (%s)', h.Tag),...
                'Callback', @obj.onChangeTag);
            uimenu(cmenu,...
                'Label', 'FaceColor',...
                'Callback', @obj.onChangeColor);
            uimenu(cmenu,...
                'Label', 'EdgeColor',...
                'Callback', @obj.onChangeColor);
            uimenu(cmenu,...
                'Label', 'FaceAlpha',...
                'Callback', @obj.onChangeAlpha);
            uimenu(cmenu,...
                'Label', 'EdgeAlpha',...
                'Callback', @obj.onChangeAlpha);
            lwMenu = uimenu(cmenu,...
                'Label', ['LineWidth ', '(', num2str(h.LineWidth), ')']);
            for i = [0.25:0.25:1.75, 2:5]
                uimenu(lwMenu,... 
                    'Label', num2str(i),...
                    'Callback', @obj.onChangeLineWidth);
            end
            
            % Keep a reference of parent graphic object
            set(cmenu, 'UserData', h);
            set(h, 'UIContextMenu', cmenu);
        end
    end
    
    % Callback
    methods (Access = private)
        function onChangeTag(~, src, ~)
            newTag = inputdlg('New Tag: ',...
                'Tag Set Dialog', 1, {'c'});
            if ~isempty(newTag)
                set(src.Parent.UserData, 'Tag', newTag{1});
            end
        end

        function onChangeLineWidth(~, src, ~)
            lw = str2double(src.Label);
            set(src.Parent.UserData, 'LineWidth', lw);
        end

        function onChangeAlpha(~, src, ~)
            set(src.Parent.UserData, src.Parent.Label, newAlpha);
        end
        
        function onChangeColor(~, src, ~)
            % ONCHANGECOLOR  Generic color control
            co = uisetcolor();
            
            switch src.Label
                case 'FaceColor'
                    set(src.Parent.UserData, 'FaceColor', co);
                case 'EdgeColor'
                    set(src.Parent.UserData, 'EdgeColor', co);
            end
        end
        
        function onExportDAE(~, src, ~)
            saveDir = uigetdir();
            fname = inputdlg('File name:',...
                'File Name Dialog', 1, {src.UserData.Tag});
            if isempty(fname) || isempty(saveDir)
                return;
            end
            writeDAE([saveDir, filesep, fname, '.dae'],...
                src.Parent.UserData.Vertices,... 
                src.Parent.UserData.Faces);
        end
    end
end