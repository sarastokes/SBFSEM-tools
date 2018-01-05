function h = volumeRender(vol, varargin)
	% VOLUMERENDER
    % 
    % Description:
    %   Render a binary volume
	% 
	% Inputs:
	%	vol 				3D binary volume (X,Y,Z)
    % Optional key,value inputs
    %   FaceColor           Color of render
    %   FaceAlpha           Transparency (0-1)
    %   doSmooth            Whether to smooth volume
    %
    % History:
    %   4Jan2017 - SSP - Separated from closed curve render code
	% ---------------------------------------------------------------------

	ip = inputParser();
	addParameter(ip, 'FaceColor', [0.5 0.5 0.5],...
		@(x) ischar(x) || isvector(x));
	addParameter(ip, 'FaceAlpha', 1, @isnumeric);
	addParameter(ip, 'doSmooth', true, @islogical);
	parse(ip, varargin{:});

    % Smooth the binary images to increase cohesion
	if ip.Results.doSmooth
		vol = smooth3(vol);
	end

	% Create a figure
	fh = sbfsem.ui.FigureView(1);
	set([fh.figureHandle, fh.ax], 'Color', 'k');
	
	% Create the 3D volume
	h = patch(isosurface(vol),...
		'FaceColor', ip.Results.FaceColor,...
		'EdgeColor', 'none',...
		'FaceLighting', 'gouraud',...
		'FaceAlpha', ip.Results.FaceAlpha,...
        'SpecularExponent', 50,...
        'SpecularColorReflectance', 0);
	
    % Set up the lighting
    lightangle(45,30);
    lightangle(225,30);
    lighting phong;
    
    % Format the axis
    view(3);
    axis equal; axis tight;
    fh.labelXYZ();
    set(fh.ax, 'XColor', 'w',...
    	'YColor', 'w', 'ZColor', 'w');