classdef ColorMaps
    
    enumeration
        Bone
        CubicL
        CubicYF
        Gray
        Haxby
        Hsv
        AntiJet
        Parula
        RedBlue
        Viridis
        Ametrine
        Isolum
    end
    
    methods
        function setMap(obj, parentHandle, N)
            % SETMAP  Applies colormap to handle
            if nargin < 3
                N = 256;
            end
            
            set(parentHandle, 'colormap', obj.getMap(N));
        end
        
        function tf = colorblind(obj)
            % COLORBLIND  Is the colormap good for red-green colorblind?
            import sbfsem.ui.Colormaps;
            if ismember(obj, {ColorMaps.Isolum, ColorMaps.Ametrine})
                tf = true;
            else
                tf = false;
            end
        end
        
        function cmap = getMap(obj, N)
            % GETMAP  Returns N values for colormap
            if nargin < 2
                N = 256;
            end
            
            import sbfsem.ui.ColorMaps;
            
            % Some of the external functions use nargchk
            warning('off', 'MATLAB:nargchk:deprecated');
            
            switch obj
                % Matlab
                case ColorMaps.Bone
                    cmap = bone(N);
                case ColorMaps.Gray
                    cmap = gray(N);
                case ColorMaps.Parula
                    cmap = parula(N);
                case ColorMaps.Hsv
                    cmap = hsv(N);
                % Improved version of jet
                case ColorMaps.AntiJet
                    cmap = antijet(N);
                % Python
                case ColorMaps.Viridis
                    cmap = viridis(N);
                % Perceptually distinct
                case ColorMaps.CubicL
                    if N > 256
                        N = 256;
                    end
                    cmap = pmkmp('CubicL', N);
                case ColorMaps.CubicYF
                    if N > 256
                        N = 256;
                    end
                    cmap = pmkmp('CubicYF', N);
                % Light-Bertlein
                case ColorMaps.RedBlue
                    cmap = fliplr(lbmap('RedBlue', N));
                % Ocean
                case ColorMaps.Haxby
                    cmap = haxby(N);
                % Colorblind
                case ColorMaps.Isolum
                    cmap = isolum(N);
                case ColorMaps.Ametrine
                    cmap = ametrine(N);
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
                % Matlab
                case 'parula'
                    obj = ColorMaps.Parula;
                case 'bone'
                    obj = ColorMaps.Bone;
                case 'gray'
                    obj = ColorMaps.Gray;
                case 'hsv'
                    obj = ColorMaps.Hsv;
                % Improved version of jet
                case {'jet', 'antijet'}
                    obj = ColorMaps.AntiJet;
                % Perceptually distinct
                case 'cubicl'
                    obj = ColorMaps.CubicL;
                case 'cubicyf'
                    obj = ColorMaps.CubicYF;
                % Python
                case 'viridis'
                    obj = ColorMaps.Viridis;
                % Light-Bertlein
                case 'redblue'
                    obj = ColorMaps.RedBlue;
                % Ocean
                case 'haxby'
                    obj = ColorMaps.Haxby;
                % Colorblind
                case 'ametrine'
                    obj = ColorMaps.Ametrine;
                case 'isolum'
                    obj = ColorMaps.Isolum;
                otherwise
                    warning('SBFSEM:UI:COLORMAPS',...
                        'Unrecognized color map');
            end
        end
    end
end