function [pts, newIM] = segmentColorROI(im, cellType, keepColor)
    % SEGMENTNEURON  Pull out a single neuron type from EM stack
    %
    % Syntax:
    %   [pts, newIM] = segmentColorROI(im, cellType, keepColor);
    %
    % Inputs:
    %   im              image
    %   cellType:       onmidget, offmidget, axon
    %   keepColor       [false], otherwise returns binary image
    %
    % Output:
    %   pts             data points within threshold bounds
    %   newIM           new image with thresholding
    % 
    % 28Oct2017 - SSP

    if nargin < 3
        keepColor = false;
    end
    
    % List of allowed cell types
    cellType = validatestring(cellType,...
        {'onmidget', 'offmidget', 'axon'});
    
    im = im2double(im);
    
    % Switch to LAB color space
    cform = makecform('srgb2lab',...
        'AdaptedWhitePoint', whitepoint('D65'));
    I = applycform(im,cform);
    
    % Get predetermined threshold values
    switch cellType
        case 'offmidget'
            chan2 = [15.465, 36.644];
            chan3 = [-30.948, 18.899];
        case 'onmidget'
            chan2 = [-32.779, -19.012];
            chan3 = [-30.948, 18.899];
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
