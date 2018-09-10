% A proof of concept tutorial to demonstrate that much of computer vision is  
% quite straightforward. Here, we'll expand a disc annotation to a closed 
% curve. This should work for most well defined branches... Performing this
% for bipolar cell axons alone, as in the example here, would save us a lot
% of time!
% 6Sept2018 - SSP

%% Load image
% Here's a random screenshot from Viking. You can import your own too, 
% but for speed make sure it's not too large.
im = imread('c649_zoom.png');

% View your image
figure(); imshow(im); title('Original image');

%% Preprocessing
% Reduce the dimensions by converting to grayscale. 
% For simplicity, I like to convert imported images to 'double' right 
% away, rather than having to keep track of different data types. 
% There are some advantages to this, but you'll see we have to jump 
% back to uint8 for some functions.
im = rgb2gray(im);

% Filter the image (experiment with the size of the smoothing kernel)
% This removes the unnecessary structure and detail but keeps the 
% important larger edges. If too much of the structure within a 
% dendrite is being detected, increase the kernel size (blurrier).
A = imgaussfilt(uint8(im), 2);
% Contrast adjustments
A = imadjust(A, stretchlim(A), []);
figure(); imshow(A); title('Processed image');

%%
% Next the image will appear and you'll select a point. Imagine this 
% is the XY position of the center of a disc annotation. This is the
% information we would extract to perform this function on real 
% annotations. 

% Try the primary dendrite in the center.
mask = regiongrowing(A);

% Now try the bipolar cell at the bottom.. not so good! 
mask = regiongrowing(A);
% To solve this, Version 2.0 would include the disc radius as well. 
% Incorporating this information would greatly improve the segmentation 
% accuracy. I will try it at some point!

