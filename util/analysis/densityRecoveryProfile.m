function [drp, binCenters] = densityRecoveryProfile(centers, numBins, binWidth, visualize)
    % DENSITYRECOVERYPROFILE  Profiles mosaic regularity
    %
    % Inputs:
    %   centers         centers of each object in mosaic
    %   numBins         number of annuli
    %   binWidth        annulus width
    % Optional Inputs:
    %   visualize       [false] plot the results
    % Outputs:
    %   drp             density recovery profile
    %   binCenters      xpts for a bar graph
    %
    % Rodieck, RW (1991) The density recovery profile: A method for the 
    %   analysis of points in the plane applicable to retinal studies"
    %   Visual Neuroscience, 6, 95-111
    %
    % 5Dec2017 - SSP
    % ---------------------------------------------------------------------
    if nargin < 4
        visualize = false;
    end
    % Pairwise distance between centers
	dists = pdist(centers);

	% Normalization for number of points
	% For auto-correlation, just the number of points
	numNorm = size(centers, 1); 

	% Also should divide by 0.5. 
	% Under Rodieck's method, each distance is counted 2x
	% numNorm is applied before divisive normalization below
	% thus multiplying by 0.5 doubles the count in each bin
	% effectively counting every distance twice
	numNorm = 0.5*numNorm;

	% Get the bin centers, adding extra bin at end to catch
	% points which are further away
	% This extra bin will be discarded later
	binCenters = binWidth/2 + (0:1:numBins)*binWidth;

	% Bin distances
    counts = hist(dists, binCenters);

	% Discard the last bin
	counts = counts(1:end-1);
    binCenters = binCenters(1:end-1);  

	% Get the area of each annulus
	areas = pi*binWidth^2 * (2*(1:numBins)-1);

	% Divide by the area and the normalization for the 
	% number of points
	drp = counts./(areas*numNorm);

    if visualize
    	figure('Name', 'Density Recovery Profile');
        bar(binCenters, drp);
    end