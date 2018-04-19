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
    %   resize              Amount to resize the input volume (0-1)
    %   Tag                 Tag for handle (default: volRender)
    % Output:
    %   h                   Patch handle
    %
    % History:
    %   4Jan2017 - SSP - Separated from closed curve render code
    %   24Mar2018 - SSP - Added patch handle output
    %   11Apr2018 - SSP - Added resize, default tag
	% ---------------------------------------------------------------------

	ip = inputParser();
    ip.CaseSensitive = false;
	addParameter(ip, 'FaceColor', [0.5 0.5 0.5],...
		@(x) ischar(x) || isvector(x));
	addParameter(ip, 'FaceAlpha', 1, @isnumeric);
	addParameter(ip, 'Tag', 'volRender', @ischar);
	addParameter(ip, 'doSmooth', true, @islogical);
	addParameter(ip, 'resize', 1, @isnumeric);
	parse(ip, varargin{:});
    
    resizeFac = ip.Results.resize;

	if resizeFac > 1
		warning('Resize must be between 0 and 1! No resize performed');
    elseif resizeFac ~= 1
		fprintf('Resizing volume by %.2f...\n', resizeFac);
        try
    		vol = imresize3(vol, resizeFac);
        catch % Older version of matlab
            oldVol = vol; vol = [];
            for i = 1:size(oldVol, 3)
                vol = cat(3, vol, imresize(squeeze(oldVol(:,:,i)), resizeFac));
            end
        end
	end

    % Smooth the binary images to increase cohesion
	if ip.Results.doSmooth
		disp('Smoothing volume...');
		vol = smooth3(vol);
	end

	% Create a figure
	fh = sbfsem.ui.FigureView(1);
	set([fh.figureHandle, fh.ax], 'Color', 'k');
	
	% Create the 3D volume
	disp('Creating surface...');
	h = patch(isosurface(vol),...
		'FaceColor', ip.Results.FaceColor,...
		'FaceAlpha', ip.Results.FaceAlpha,...
		'EdgeColor', 'none',...
		'FaceLighting', 'gouraud',...
        'SpecularExponent', 50,...
        'SpecularColorReflectance', 0,...
        'Tag', ip.Results.Tag);
	disp('Creating normals...')
	isonormals(vol, h);

    % Set up the lighting
    lightangle(45, 30);
    lightangle(225, 30);
    lighting phong;
    
    % Format the axis
    view(3);
    axis equal; axis tight;
    fh.labelXYZ();
    set(fh.ax, 'XColor', 'w',...
    	'YColor', 'w', 'ZColor', 'w');