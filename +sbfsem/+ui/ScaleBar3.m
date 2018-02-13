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
            
			obj.createUi();
		end
	end

	% Private line/text methods
	methods (Access = private)
		function createUi(obj)
            % CREATEUI  Create the line and text objects
            
			obj.createLine();
			obj.createLabel();
		end

		function createLine(obj)
			% CREATELINE  Get the data points and create scalebar line

			% Delete existing line (if any)
			obj.deleteLine();
            
            [x, y, z] = obj.getXYZPoints(obj.xyz0, obj.barSize);

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
        
        function onSelectedTextProperties(obj, ~, ~)
            inspect(obj.hText);
        end
        
        function onSelectedLineProperties(obj, ~, ~)
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
                return;
            end
			obj.xyz0 = [str2double(ret{1}), str2double(ret{2}), str2double(ret{3})];
            obj.barSize = str2double(ret{4});
			obj.units = ret{5};
		end
	end

	methods (Static)
		function [x, y, z] = getXYZPoints(xyz, w)
            % GETXYZPOINTS  Get the XYZ points to create scalebar
            %
            % Inputs:
            %   xyz         Origin XYZ coordinates (3x1 vector)
            %   w           Bar size
            % Outputs:
            %   x, y, z     Points for plotting
            
		    % NaNs keep scalebar lines disconnected
			x = [xyz(1), xyz(1)-w, NaN, xyz(1), xyz(1), NaN, xyz(1), xyz(1)];
			y = [xyz(2), xyz(2), NaN, xyz(2), xyz(2)-w, NaN, xyz(2), xyz(2)];
			z = [xyz(3), xyz(3), NaN, xyz(3), xyz(3), NaN, xyz(3), xyz(3)+w];
		end

		function deleteScalebars(axHandle)
			% DELETESCALEBARS
			delete(findall(axHandle, 'Tag', 'scalebar'));
		end
	end
end