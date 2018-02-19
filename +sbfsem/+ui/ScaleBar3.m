classdef ScaleBar3 < handle
    % SCALEBAR3
    %
    % Description:
    %   A 3D scale bar with bars in the X, Y, and Z directions
    %
    % Constructor:
    %   obj = ScaleBar3(axHandle, xyz0, barSize);
    %
    % Inputs:
    %	ax 			Parent axes handle
    % 	xyz0 		XYZ coordinates of origin
    %	barSize 	Length of scale bars
    %
    % Note:
    %   If xyz0 and/or barSize aren't provided as arguments, a dialog box will
    %   request the information.
    %
    % Example:
    %   figure(); view(3);
    %   xlim([0 1]); ylim([0 1]); zlim([0 1]);
    %   % Add a scalebar centered at 0.5,0.5,0.5 with size 0.2
    %   x = ScaleBar3(gca, [0.5 0.5 0.5], 0.2);
    %   % Add a second scalebar using dialog box
    %   x2 = ScaleBar3(gca);
    %
    % History:
    %   12Feb2018 - SSP
    %	15Feb2018 - Added 1-2D options, todo: fix textbox
    % -------------------------------------------------------------------------
    
    properties (SetAccess = private)
        hLine = [];
        hText = [];
        hParent
        
        xyz0
        barSize
        units = '';
        
        Color
        FontSize = 16;
        FontName = 'Segoe UI';
    end
    
    methods
        function obj = ScaleBar3(ax, xyz0, barSize)
            % SCALEBAR3  Constructor
            %
            % Inputs:
            %	ax 			Parent axes handle
            % 	xyz0 		XYZ coordinates of origin
            %	barSize 	Length of scale bars
            %
            % Note:
            %	if xyz0 and barSize aren't included as arguments, a
            % 	dialog box will open up
            
            assert(isa(ax, 'matlab.graphics.axis.Axes'),...
                'Input an axes handle');
            obj.hParent = ax;
            
            % Assign xyz0 if possible for settings dialog defaults
            if nargin > 1
                obj.xyz0 = xyz0;
            else
                obj.xyz0 = [0 0 0];
            end
            
            if nargin < 3
                % Open up a dialog box for origin and length
                obj.barSize = 0;
                obj.settingsDialog();
            else
                obj.barSize = barSize;
            end
            
            % The scale bar should be the opposite color of axes
            if nnz(obj.hParent.Color) == 0
                obj.Color = 'w';
            else
                obj.Color = 'k';
            end
            
            % Create the scale bar and label
            hold(obj.hParent, 'on');
            obj.createLine();
            obj.createLabel();
        end
    end
    
    % Private line/text methods
    methods (Access = private)
        
        function createLine(obj, whichAxes)
            % CREATELINE  Get the data points and create scalebar line
            %
            % Optional inputs:
            %	whichAxes 		'x', 'y', 'z' or 'all' (default = all)
            % ----------------------------------------------------------
            
            if nargin < 2
                whichAxes = 'all';
            end
            % Delete existing line (if any)
            obj.deleteLine();
            
            [x, y, z] = obj.getXYZPoints(obj.xyz0, obj.barSize, whichAxes);
            
            obj.hLine = line(obj.hParent, x, y, z,....
                'Color', obj.Color,...
                'LineWidth', 1.5,...
                'Tag', 'scalebar');
            
            set(obj.hLine, 'UIContextMenu', obj.getContextMenu());
        end
        
        function createLabel(obj)
            % CREATELABEL  Create the scalebar text object
            
            % Delete existing label (if any)
            obj.deleteLabel();
            
            str = [num2str(obj.barSize), ' ', obj.units];
            obj.hText = text(obj.xyz0(1), obj.xyz0(2), obj.xyz0(3), str,...
                'Color', obj.Color,...
                'VerticalAlignment', 'bottom',...
                'HorizontalAlignment', 'left',...
                'FontSize', obj.FontSize,...
                'FontName', obj.FontName,...
                'Tag', 'scalebar');
            
            set(obj.hText, 'UIContextMenu', obj.getContextMenu());
        end
        
        function deleteLabel(obj)
            % DELETELABEL  Delete text object and clear out property
            delete(findall(obj.hParent, 'Tag', 'scalebar', 'Type', 'text'));
            obj.hText = [];
        end
        
        function deleteLine(obj)
            % DELETELINE  Delete line object and clear out property
            delete(findall(obj.hParent, 'Tag', 'scalebar', 'Type', 'line'));
            obj.hLine = [];
        end
        
        function c = getContextMenu(obj)
            % GETCONTEXTMENU  Create the line and text object context menu
            c = uicontextmenu();
            uimenu(c, 'Label', 'Modify ScaleBar',...
                'Callback', @obj.onSelectedModify);
            axList = 'XYZ';
            for i = 1:3
                uimenu(c, 'Label', sprintf('%s-axis only', axList(i)),...
                    'Tag', axList(i),...
                    'Callback', @obj.onSelectedLimitAxes);
            end
            uimenu(c, 'Label', 'Y-axis only',...
                'Tag', 'Y',...
                'Callback', @obj.onSelectedLimitAxes);
            uimenu(c, 'Label', 'Z-axis only',...
                'Tag', 'Z',...
                'Callback', @obj.onSelectedLimitAxes);
            uimenu(c, 'Label', 'Omit X',...
            	'Tag', 'YZ',...
            	'Callback', @obj.onSelectedLimitAxes);
            uimenu(c, 'Label', 'Omit Y',...
            	'Tag', 'XZ',...
            	'Callback', @obj.onSelectedLimitAxes);
            uimenu(c, 'Label', 'Omit Z',...
            	'Tag', 'XY',...
            	'Callback', @obj.onSelectedLimitAxes);
            uimenu(c, 'Label', 'Text Properties',...
                'Callback', @obj.onSelectedTextProperties);
            uimenu(c, 'Label', 'Line Properties',...
                'Callback', @obj.onSelectedLineProperties);
        end
    end
    
    % Callback methods
    methods (Access = private)
        function onSelectedModify(obj, ~, ~)
            % ONSELECTEDMODIFY  Open dialog and apply changes

            obj.settingsDialog();
            obj.createLine();
            obj.createLabel();
        end
        
        function onSelectedLimitAxes(obj, src, ~)
            % ONSELECTEDLIMITAXES

            obj.createLine(src.Tag);
        end
        
        function onSelectedTextProperties(obj, ~, ~)
            % ONSELECTEDTEXTPROPERTIES

            inspect(obj.hText);
        end
        
        function onSelectedLineProperties(obj, ~, ~)
            % ONSELECTEDLINEPROPERTIES
            
            inspect(obj.hLine);
        end
        
        function settingsDialog(obj)
            % SETTINGSDIALOG Opens dialog box, sets xyz0, barSize, units
            
            ret = inputdlg(...
                {'X origin', 'Y origin', 'Z origin', 'length', 'units'},...
                'Scalebar Settings Dialog', 1,...
                {num2str(obj.xyz0(1)), num2str(obj.xyz0(2)),...
                num2str(obj.xyz0(3)), num2str(obj.barSize), obj.units});
            if isempty(ret)
                obj.xyz0 = [str2double(ret{1}), str2double(ret{2}), str2double(ret{3})];
            	obj.barSize = str2double(ret{4});
            	obj.units = ret{5};
            end
        end
    end
    
    methods (Static)
        function [x, y, z] = getXYZPoints(xyz, w, whichAxes)
            % GETXYZPOINTS  Get the XYZ points to create scalebar
            %
            % Inputs:
            %   xyz         Origin XYZ coordinates (3x1 vector)
            %   w           Bar size
            %   whichAxes   Which axes to plot (char: 'x', 'y' or 'z')
            %
            % Outputs:
            %   x, y, z     Points for plotting
            % -------------------------------------------------------------
            
            % NaNs keep scalebar lines disconnected
            x = [xyz(1), xyz(1)-w, NaN, xyz(1), xyz(1), NaN, xyz(1), xyz(1)];
            y = [xyz(2), xyz(2), NaN, xyz(2), xyz(2)-w, NaN, xyz(2), xyz(2)];
            z = [xyz(3), xyz(3), NaN, xyz(3), xyz(3), NaN, xyz(3), xyz(3)+w];
            
            if nargin == 3
                switch lower(whichAxes)
                    case 'x'
                        pts = 1:2;
                    case 'y'
                        pts = 4:5;
                    case 'z'
                        pts = 7:8;
                    case 'xy'
                    	pts = 1:5;
                    case 'yz'
                    	pts = 4:8;
                    case 'xz'
                    	pts = [1:3, 7:8];
                    otherwise
                        return;
                end
                [x, y, z] = keepPts(x, y, z, pts);
            end
            
            function [a, b, c] = keepPts(a, b, c, whichPts)
                % KEEPPTS
                a = a(whichPts); b = b(whichPts); c = c(whichPts);
            end
        end
        
        function deleteScalebars(axHandle)
            % DELETESCALEBARS
            delete(findall(axHandle, 'Tag', 'scalebar'));
        end
    end
end