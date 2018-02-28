function [pts, newIM] = segmentColorROI(im, cellType, keepColor)
    % SEGMENTNEURON  Pull out a single neuron type from EM stack
    %
    % Syntax:
    %   [pts, newIM] = segmentColorROI(im, cellType, keepColor);
    %
    % Inputs:
    %   im              image
    %   cellType:       onmidget, offmidget (or 'r', 'g', 'b')
    %   keepColor       [false], otherwise returns binary image
    %
    % Output:
    %   pts             data points within threshold bounds
    %   newIM           new image with thresholding
    % 
    % History:
    %   28Oct2017 - SSP
    %   27Feb2018 - SSP - Addition of RGB channel thresholding
    % ---------------------------------------------------------------------

    if nargin < 3
        keepColor = false;
    end
    
    % Get predetermined threshold values
    switch lower(cellType)
        case 'offmidget'
            chan2 = [15.465, 36.644];
            chan3 = [-30.948, 18.899];
        case 'onmidget'
            chan2 = [-32.779, -19.012];
            chan3 = [-30.948, 18.899];
        case 'r' % [1 0 0]
            chan2 = [9.795, 37.724];
            chan3 = [6.335, 38.728];
        case 'g' % [0 1 0]
            chan2 = [-44.279, -19.684];
            chan3 = [0.409, 38.728];
        case 'b' % [0 0 1]
            chan2 = [-44.279, 37.724];
            chan3 = [-49.596, -27.568];
        case 'y' % [1 1 0] not recommended
            chan2 = [-30.760, -15.138];
            chan3 = [26.129, 94.482];
        otherwise
            error('Unrecognized cell/channel type');
    end

    
    % Switch to LAB color space
    try % Matlab2017
        I = rgb2lab(im);
    catch
        im = im2double(im);
        cform = makecform('srgb2lab',...
            'AdaptedWhitePoint', whitepoint('D65'));
        I = applycform(im,cform);
    end
    
    % Pull only the points matching those thresholds
    pts = I(:,:,1) &...
        (I(:,:,2) >= chan2(1)) & (I(:,:,2) <= chan2(2)) &...
        (I(:,:,3) >= chan3(1)) & (I(:,:,3) <= chan3(2));
    
    if keepColor
        newIM = im;
    else  
        newIM = true(size(im));
    end
    
    newIM(repmat(~pts, [1 1 3])) = 0;
