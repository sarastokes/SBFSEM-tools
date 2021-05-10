classdef FigureView < handle
% FIGUREVIEW
%
% Description:
%   A Figure class for sbfsem-tools
%
% Constructor:
%   obj = SBFSEM.UI.FIGUREVIEW(argin);
%
% Inputs:
%   argin       Either the number of axes for a new figure
%               or the handle to an existing figure
%
% Examples:
%   obj = sbfsem.ui.FigureView(1);
%   obj = sbfsem.ui.FigureView(gcf);
%
% Properties:
%   figureHandle    Matlab figure handle
%   ax              Axes handle(s)
%   numAxes         Number of axes
%
% Methods:
%   obj.title(str, axNum);
%   obj.setColormap(colormapName);
%   obj.setDAspect(source);
%   obj.labels(xyz, axNum);
%   obj.xyzLabels(axNum);
%   obj.close();
%
% History:
%   ? - SSP
%   7Feb2018 - Constructor now takes matlab figures as input
%   30Dec2020- Added standard 3D render settings to axes
% -------------------------------------------------------------------------
    
    properties (SetAccess = protected, GetAccess = public)
        figureHandle
    end
    
    properties (Access = public)
        ax
    end
    
    properties (Access = protected)
        numAxes
    end
    
    methods
        function obj = FigureView(argin)
            % FIGUREVIEW  Constructor
            
            if nargin == 0
                obj.numAxes = 1;                
                obj.makeFigure();
            elseif isnumeric(argin)
                obj.numAxes = argin;
                obj.makeFigure();
            elseif ishandle(argin)
                obj.figureHandle = argin;
                obj.ax = findall(obj.figureHandle, 'Type', 'axes');
            end
            
            set(obj.figureHandle,...
                'DefaultAxesTitleFontWeight', 'normal',...
                'DefaultAxesFontName', 'Segoe UI',...
                'DefaultAxesTickDir', 'out',...
                'DefaultAxesBox', 'off',...
                'InvertHardCopy', 'off');
        end
        
        function close(obj)
            % CLOSE
            delete(obj.figureHandle);
        end
        
        function title(obj, str, axNum)
            % TITLE
            %
            % Inputs:
            %   str         Title (char)
            %   axNum       Axis number to plot to (int, default = 1)
            
            if nargin < 3
                axHandle = obj.ax;
            else
                axHandle = obj.ax(axNum);
            end
            title(axHandle, str);
        end
        
        function setDAspect(obj, source)
            % SETDASPECT
            %
            % Description:
            %   Set XYZ axis scaling based on volume dimensions
            % 
            % Input:
            %   source      volume name/abbreviation (str)
            
            if numel(obj.ax) > 1
                volumeScale = getDAspectFromOData(source);
                for i = 1:numel(obj.ax)
                    daspect(obj.ax(i), volumeScale);
                    axis(obj.ax(i), 'equal');
                end
            else
                daspect(obj.ax, getDAspectFromOData(source));
                axis(obj.ax, 'equal');
            end
        end
        
        function setColormap(obj, mapName)
            % SETCOLORMAP
            % 
            % Input:
            %   mapName     color map name (char)
            %
            % Note: if no mapname input, returns available colormaps to the
            %   command line. These are:
            %   'redblue', 'redblue2', 'parula', 'bone', 'cubicl'
            % -------------------------------------------------------------
            switch mapName
                case 'redblue'
                    colormap(obj.ax, flipud(lbmap(256, 'redblue')));
                case 'redblue2'
                    colormap(obj.ax, fliplr(lbmap(256, 'redblue')));
                case 'parula'
                    colormap(obj.ax, 'parula');
                case 'bone'
                    colormap(obj.ax, 'bone');
                case 'cubicl'
                    colormap(obj.ax, pmkmp(256, 'cubicl'));
                otherwise
                    disp('map name not recognized');
                    disp('allowed map names:')
                    disp('redblue, redblue2, parula, bone, cubicl');
            end
        end
        
        
        function labels(obj, xyz, axNum)
            % LABELS
            % 
            % Description:
            %   Label the X, Y and Z axes
            %
            % Inputs:
            %   xyz     cellstr of labels {'x', 'y', 'z'}
            % Optional inputs:
            %   axNum   axis number to label (int, default = 1)
            % -------------------------------------------------------------
            if nargin < 3
                axHandle = obj.ax;
            else
                axHandle = obj.ax(axNum);
            end
            
            xlabel(axHandle, xyz{1});
            ylabel(axHandle, xyz{2});
            if numel(xyz) == 3
                zlabel(axHandle, xyz{3});
            end
        end
        
        function labelXYZ(obj, axNum)
            % LABELXYZ
            %
            % Description:
            %   Label each axes as 'x-axis', 'y-axis', 'z-axis'
            %
            % Inputs:
            %   axNum       which axes (int, default = 1)
            % -------------------------------------------------------------
            if nargin < 2
                axHandle = obj.ax;
            else
                axHandle = obj.ax(axNum);
            end
            xlabel(axHandle, 'x-axis');
            ylabel(axHandle, 'y-axis');
            zlabel(axHandle, 'z-axis');
        end
    end
    
    methods (Access = private)
        function makeFigure(obj)
            obj.figureHandle = figure();
            if obj.numAxes == 1
                obj.ax = axes('Parent', obj.figureHandle);
                lightangle(obj.ax, 45, 30);
                lightangle(obj.ax, 225, 30);
                hold(obj.ax, 'on');
            elseif obj.numAxes > 1
                obj.ax = struct();
                for i = 1:obj.numAxes
                    obj.ax(i) = axes('Parent', obj.figureHandle);
                    lightangle(obj.ax(i), 45, 30);
                    lightangle(obj.ax(i), 225, 30);
                    hold(obj.ax, 'on');
                end
            end
        end
    end    
end

