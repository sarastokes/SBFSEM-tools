classdef FigureView < handle

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
		function obj = FigureView(numAxes)
			obj.figureHandle = figure();
			set(obj.figureHandle,...
				'DefaultAxesTitleFontWeight', 'normal',...
				'DefaultAxesFontName', 'Segoe UI',...
				'DefaultAxesTickDir', 'out',...
				'DefaultAxesBox', 'off');

			if nargin == 0
				obj.numAxes = 1;
			else
				obj.numAxes = numAxes;
			end

			if obj.numAxes == 1
				obj.ax = axes('Parent', obj.figureHandle);
			elseif obj.numAxes > 1
				obj.ax = struct();
				for i = 1:obj.numAxes
					obj.ax(i) = axes('Parent', obj.figureHandle);
				end
			end
		end

		function title(obj, str, axNum)
			if nargin < 3
				axHandle = obj.ax;
            else
                axHandle = obj.ax(axNum);
			end
			title(axHandle, str);
		end

		function setDAspect(obj, source)
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
			end
		end


		function labels(obj, xyz, axNum)
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
end

