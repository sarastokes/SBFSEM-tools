%% TUTORIAL - Adding scale bars to exported frames from Viking

% Create an instance of the Viking frame class. The input is the volume 
% name or abbreviation
x = sbfsem.image.VikingFrame('i');
% Using the default export size of 2500 pixels
% Return the size, in inches, of a 25 micron scale bar
scalebar = x.um2in(2)



% If you exported an image in Illustrator at a pixel size other than 2500
% or have already resized the image, input the pixel size and image size as
% the 3rd and 4th arguments
scalebar = x.um2in(2, 2500, 13.0227)

% The output is the line size in inches of the scalebar. Add it in Adobe
% Illustrator.