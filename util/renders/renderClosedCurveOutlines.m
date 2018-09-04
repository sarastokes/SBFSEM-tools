function vol = renderClosedCurveOutlines(neuron, splinePts)
    % 
    % History:
    %   9Apr2018 - first working version

    assert(isa(neuron, 'NeuronAPI'), 'Input Neuron object');
    
    % TODO: add return for non-cc objects (prob in setGeometries)
    if isempty(neuron.geometries)
        neuron.setGeometries();
        if isempty(neuron.geometries)
            error('SBFSEM:RENDERCLOSEDCURVEOUTLINES',...
                'No geometries imported from OData!');
        end
    end
    T = neuron.geometries;
    
    % Convert to ClosedCurve
    Z = [];
    imnodes = cell(0,1);
    for i = 1:height(T)
        imnodes = cat(1, imnodes,...
             sbfsem.builtin.ClosedCurve(T(i,:)));
         Z = cat(1, Z, T.Z(i,:));
    end
    
    % Round the outlines here for bounding box calc, cutouts later
    for i = 1:numel(imnodes)
        imnodes(i).outline = round(imnodes(i).outline,2)*100;
    end

    % Find the xy limits to use as bounding box
    fprintf('Calculating bounding box ');
    boundingBox = [ min(imnodes(1).outline(:,1)),...
        max(imnodes(1).outline(:,1)),...
        min(imnodes(1).outline(:,2)),...
        max(imnodes(1).outline(:,2))];
    for i = 2:numel(imnodes)
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
    fprintf('= (%u  %u), (%u  %u)\n', boundingBox);
    
    % Here's where the updates start!
    % Volume coordinates (padded by 1 so no 0s as indexes)
    xmin = boundingBox(1)-1; ymin = boundingBox(3)-1;
    xmax = boundingBox(2); ymax = boundingBox(4);  
    xrange = xmax-xmin; yrange = ymax-ymin;
    zList = sort(unique(T.Z), 'ascend');
    
    % The unique Z values are used rather than number of imnodes so that
    % multiple annotations per z-section work.
    vol = ndgrid(1:xrange, 1:yrange, 1:numel(unique(T.Z)));
    
    % This is excessive here, would be minimized later
    for i = 1:numel(imnodes)
        % Get the index for the Z section
        zInd = find(zList == imnodes(i).Z(1));
        
        % Translate outline points into the bounding box
        outlinePts = bsxfun(@minus, imnodes(i).outline, [xmin, ymin]);
        outlinePts = round(outlinePts);
        % Smooth with catmull rom spline
        [x, y] = getSpline(outlinePts(:,1), outlinePts(:,2), splinePts);
        % Only integers above 0
        x = floor(x); y = floor(y);
        x(x <= 0) = 1; y(y <= 0) = 1;
        
        % Check for cutouts
        if isempty(imnodes(i).cutouts)
            BW = mpoly2mask([x', y'], [size(vol, 1), size(vol, 2)]);
        else
            % Create the adjacency matrix
            A = deal(false(numel(imnodes(i).cutouts) + 1));
            A(2:end,1) = true;
            % Init cell array for xy points, beginning with the outline
            xyPts = cell(0,1);
            xyPts = cat(1, xyPts, [x',y']);
            
            % Process and add each cutout
            for j = 1:numel(imnodes(i).cutouts)
                % Several corrections must be applied:
                curvePoints = imnodes(i).cutouts{j};
                if nnz(isnan(curvePoints(1,:))) > 0
                    curvePoints(1,:) = curvePoints(end,:);
                end
                % Whole numbers for the bounding box
                curvePoints = round(curvePoints * 100);
                curvePoints = bsxfun(@minus, curvePoints, [xmin, ymin]);
                [x, y] = getSpline(curvePoints(:,1), curvePoints(:,2), splinePts);
                x = round(x); y = round(y);
                xyPts = cat(1, xyPts, [x', y']);
            end            
            BW = mpoly2mask(xyPts, [size(vol,1), size(vol,2)], A);
        end
        vol(:, :, zInd) = BW; %#ok<FNDSB>
    end
end

function [x, y] = getSpline(x0, y0, N)
    % GETSPLINE  Pad x,y vectors for catmull-rom spline
    x0 = x0(:);
    y0 = y0(:);
    x0 = cat(1, x0, x0(1:3));
    y0 = cat(1, y0, y0(1:3));
    [x, y] = catmullRomSpline(x0, y0, N);
end
    

    
    
    