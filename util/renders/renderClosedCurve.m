function hiso = renderClosedCurve(neuron, varargin)
    % RENDERCLOSEDCURVE  3D structure from arbitrary geometry
    %
    % Inputs:       neuron object
    % Optional:
    %       update      false       fetch neuron geometries
    %       color       gray        FaceColor
    %       alpha       1           FaceAlpha (transparency of render)
    % Output: handle to 3D Patch object
    % 9Nov2017 - SSP

    assert(isa(neuron, 'Neuron'),...
        'Input Neuron object');

    % Parse additional inputs
    ip = inputParser();
    addParameter(ip, 'update', false, @islogical);
    addParameter(ip, 'color', [0.7, 0.7, 0.7],...
        @(x) isvector(x) || ischar(x));
    addParameter(ip, 'alpha', 1, @isfloat);
    parse(ip, varargin{:});
    faceColor = ip.Results.color;
    faceAlpha = ip.Results.alpha;
    if ischar(faceColor)
        switch faceColor
            case {'l', 'm'}
                faceColor = [0.65, 0.08, 0.18];
            case 's'
                faceColor = [0, 0.3, 0.9];
        end
    end

    % TODO: add return for non-cc objects (prob in setGeometries)
    if ip.Results.update || isempty(neuron.geometries)
        neuron.setGeometries();
    end
    T  = neuron.geometries;

    % Convert to ClosedCurve
    imnodes = cell(0,1);
    for i = 1:height(T)
        imnodes = cat(1, imnodes,...
            sbfsem.core.ClosedCurve(T.Curve{i}));
    end

    % Find the xy limits to use as bounding box
    fprintf('Calculating bounding box ');
    boundingBox = [ min(imnodes(1).outline(:,1)),...
        max(imnodes(1).outline(:,1)),...
        min(imnodes(1).outline(:,2)),...
        max(imnodes(1).outline(:,2))];
    for i = 2:numel(imnodes)
    	% TODO: optimize this
        if boundingBox(1) > min(imnodes(i).outline(:,1))
            boundingBox(1) = min(imnodes(i).outline(:,1));
        end
        if boundingBox(2) < max(imnodes(i).outline(:,1))
            boundingBox(2) = max(imnodes(i).outline(:,1));
        end
        if boundingBox(3) > min(imnodes(i).outline(:,2))
            boundingBox(3) = min(imnodes(i).outline(:,2));
        end
        if boundingBox(4) < max(imnodes(i).outline(:,2))
            boundingBox(4) = max(imnodes(i).outline(:,2));
        end
    end
    fprintf('= (%u  %u), (%u  %u)\n', round(boundingBox));


    disp('Binarizing closed curves');
    % Get the XY limits
    F = cell(0,1);
    xy = zeros(numel(imnodes), 2);
    for i = 1:numel(imnodes)
    	% Set the bounding box
    	imnodes(i).setBoundingBox(boundingBox);
        % Binarize and downsample
        F = cat(1, F, imnodes(i).resize(0.5));
        % Keep a running count on image sizes
        xy(i,:) = size(imnodes(i).binaryImage);
    end
    % Find the maximum for X and Y dimensions
    xy = max(xy);

    % Resize the binary images to xy limits
    binaryMatrix = [];
    for i = 1:numel(imnodes)
        im = F{i};
        if size(im,1) < xy(1)
        	pad = xy(1)-size(im,1);
        	fprintf('Image %u: Added %u to x-axis\n', i, pad);
            im = padarray(im, [pad, 0], 0, 'pre');
        end
        if size(im,2) < xy(2)
        	pad = xy(2)-size(im,2);
        	fprintf('Image %u: Added %u to y-axis\n', i, pad);
            im = padarray(im, [0, pad], 0, 'pre');
        end
        binaryMatrix = cat(3, binaryMatrix, im);
    end

    % Smooth the binary images to increase cohesion
    smoothedImages = smooth3(binaryMatrix);

    % Create the 3D structure
    fh = sbfsem.ui.FigureView(1);
    hiso = patch(isosurface(smoothedImages),...
    	'Parent', fh.ax,...
        'FaceColor', faceColor,...
        'EdgeColor', 'none',...
        'FaceAlpha', faceAlpha);
    isonormals(smoothedImages, hiso);

    % Set up the lighting
    view(35, 30);
    lgt = camlight(90, 90);
    lgt.Style = 'Local';
    set(hiso,...
    	'FaceLighting', 'gouraud',...
        'SpecularExponent', 50,...
        'SpecularColorReflectance', 0);

    % Scale axis to match volume dimensions
    daspect(neuron.getDAspect);
    axis equal;
    fh.labelXYZ();