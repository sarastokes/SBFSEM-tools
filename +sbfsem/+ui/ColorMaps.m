classdef ColorMaps

	enumeration
		Parula
		CubicL
		CubicYF
		Jet
		Viridis
		RedBlue
		Bone
	end

	methods
		function setMap(obj, h, N)
			% SETMAP  Applies colormap to handle
			if nargin < 3
				N = 256;
			end

			set(h, 'colormap', obj.getMap(N));
		end

		function cmap = getMap(obj, N)
			% GETMAP  Returns N values for colormap
			if nargin < 2
				N = 256;
			end
			import sbfsem.ui.ColorMaps;

			switch obj
				% Matlab
				case ColorMaps.Parula
					cmap = parula(N);
				case ColorMaps.Bone
					cmap = bone(N);
				case ColorMaps.Jet
					cmap = jet(N);
				% Python
				case ColorMaps.Viridis
					cmap = viridis(N);
				% Perceptually distinct
				case ColorMaps.CubicL
					cmap = pmkmp('CubicL', N);
				case ColorMaps.CubicYF
					cmap = pmkmp('CubicYF', N);
				% Light-Bertlein
				case ColorMaps.RedBlue
					cmap = fliplr(lbmap('RedBlue', N));
				otherwise
					warning('SBFSEM:UI:COLORMAPS',...
						'Unrecognized color map');
			end
		end
	end

	methods (Static)
		function obj = fromChar(str)
			import sbfsem.ui.ColorMaps;
			switch lower(str)
				case 'parula'
					obj = ColorMaps.Parula;
				case 'bone'
					obj = ColorMaps.Bone;
				case 'jet'
					obj = ColorMaps.Jet;
				case 'cubicl'
					obj = ColorMaps.CubicL;
				case 'cubicyf'
					obj = ColorMaps.CubicYF;
				case 'viridis'
					obj = ColorMaps.Viridis;
				case 'redblue'
					obj = ColorMaps.RedBlue;
				otherwise
					warning('SBFSEM:UI:COLORMAPS',...
						'Unrecognized color map');
			end
		end
	end
end