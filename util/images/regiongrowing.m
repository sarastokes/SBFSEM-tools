function [bpoly, J] = regiongrowing(I, varargin)
% This function performs "region growing" in an image from a specified
% seedpoint (x,y)
%
% J = regiongrowing(I,x,y,t) 
% 
% I : input image 
% J : logical output image of region
% seed_pts : the position of the seedpoint (if not given uses function getpts)
% t : maximum intensity distance (defaults to 0.2)
%
% The region is iteratively grown by comparing all unallocated neighbouring pixels to the region. 
% The difference between a pixel's intensity value and the region's mean, 
% is used as a measure of similarity. The pixel with the smallest difference 
% measured this way is allocated to the respective region. 
% This process stops when the intensity difference between region mean and
% new pixel become larger than a certain treshold (t)
%
% Example:
%
% I = im2double(imread('medtest.png'));
% x=198; y=359;
% J = regiongrowing(I,x,y,0.2); 
% figure, imshow(I+J);
%
% Author: D. Kroon, University of Twente
% Modified by Sara Patterson, University of Washington

% Ensure image is in correct format
I = im2double(I);
if numel(size(I)) == 3
    I = rgb2gray(I);
end

ip = inputParser();
ip.CaseSensitive = false;
addParameter(ip, 'Pts', [], @(x) isvector(x));
addParameter(ip, 'MaxDist', 0.2, @isnumeric);
addParameter(ip, 'Verbose', true, @islogical);
parse(ip, varargin{:});

reg_maxdist = ip.Results.MaxDist;
if isempty(ip.Results.Pts)
    figure(); imshow(I, []);
    title('Select a point, then press enter'); drawnow;
    [y, x] = getpts();
    title(''); drawnow;
    y = round(y(1));
    x = round(x(1));
    if ip.Results.Verbose
        fprintf('Points are %u, %u\n', y, x);
    end
else
    x = ip.Results.Pts(2);
    y = ip.Results.Pts(1);
end

% Output 
J = zeros(size(I)); 
% Dimensions of input image
Isizes = size(I); 

% The mean of the segmented region
reg_mean = I(x, y); 
% Number of pixels in region
reg_size = 1; 

% Free memory to store neighbours of the (segmented) region
neg_free = 10000; 
neg_pos = 0;
neg_list = zeros(neg_free, 3); 

% Distance of the region newest pixel to the regio mean
pixdist = 0; 

% Neighbor locations (footprint)
neigb = [-1 0; 1 0; 0 -1; 0 1];

% Start regiogrowing until distance between region and posible new pixels become
% higher than a certain treshold
while pixdist < reg_maxdist && reg_size < numel(I)

    % Add new neighbors pixels
    for j = 1:4
        % Calculate the neighbour coordinate
        xn = x + neigb(j, 1); 
        yn = y + neigb(j, 2);
        
        % Check if neighbour is inside or outside the image
        ins = (xn >= 1) && (yn >= 1) && (xn <= Isizes(1)) && (yn <= Isizes(2));
        
        % Add neighbor if inside and not already part of the segmented area
        if ins && (J(xn, yn) == 0)
                neg_pos = neg_pos + 1;
                neg_list(neg_pos, :) = [xn yn I(xn,yn)]; 
                J(xn,yn)=1;
        end
    end

    % Add a new block of free memory
    if neg_pos+10 > neg_free
        neg_free = neg_free + 10000; 
        neg_list((neg_pos+1):neg_free, :) = 0; 
    end
    
    % Add pixel with intensity nearest to the mean of the region, to the region
    dist = abs(neg_list(1:neg_pos, 3) - reg_mean);
    [pixdist, index] = min(dist);
    J(x, y) = 2; 
    reg_size = reg_size + 1;
    
    % Calculate the new mean of the region
    reg_mean = (reg_mean*reg_size + neg_list(index,3)) / (reg_size+1);
    
    % Save the x and y coordinates of the pixel (for the neighbour add proccess)
    x = neg_list(index, 1); 
    y = neg_list(index, 2);
    
    % Remove the pixel from the neighbour (check) list
    neg_list(index, :) = neg_list(neg_pos, :); 
    neg_pos = neg_pos - 1;
end

% Return the segmented area as logical matrix
J = J > 1;

% Return the boundary of the segmented area
bpoly = bwboundaries(J, 'noholes');
if numel(bpoly) > 1
    warning('Found %u boundaries', numel(bpoly));
end
bpoly = bpoly{1};

if ip.Results.Verbose
    ax = axes('Parent', figure()); 
    imshow(I);
    title(ax, 'Detected closed curve')
    % imshow(imoverlay(I, J, 'cyan'));
    hold(ax, 'on');
    plot(bpoly(:, 2), bpoly(:, 1), '--r', 'LineWidth', 1.5);
end