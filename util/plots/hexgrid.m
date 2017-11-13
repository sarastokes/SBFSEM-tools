% HEXGRID  Hex coordinates from compass directions

	% these are like unit vectors
	% east = [1, 0, -1];
	% northeast = [0, 1, -1];
	% northwest = [-1, 1, 0];
	% west = [-1, 0, 1];
	% southwest = [0, -1, 1];
	% southeast = [1, -1, 0];

	% radius+gap should equal 1
	radius = 0.95; % cone radius
	gap = 0.05; % half of the spacing between each cone
	pts = 100; % data points per cone
	numY = 1; % rings out from first cone
	
	% don't change these
	directions = {'nw', 'ne', 'e', 'se', 'sw', 'w'};
	coneSigma = radius/2.75;
	spacing = (radius + gap);
	numX = 6;

	conePts = pts/2 * radius;
	coneSigma = pts * coneSigma;

	yo = 0; xo = 0;

	X = zeros(numY, numX);
	Y = zeros(numY, numX);
	xx = []; yy = [];

	for ring = 1:numY
		for vec = 1:numel(directions)
			[X(ring, vec), Y(ring, vec)] = getHexagonalXY( ...
				directions{vec}, ring, [xo yo], spacing);
			if ring > 1
				tmp = circshift(directions, [0,-2]);	
				for branch = 1:(ring-1)
					[xx(end+1),yy(end+1)] = getHexagonalXY(tmp{vec},... 
						branch, [X(ring, vec), Y(ring, vec)], spacing);
				end
			end
		end
	end

	X = X(:); Y = Y(:);

	figure('Name', 'Cone Grid'); 
	axis equal; hold on;
	plot(xo, yo, 'ok');
	plot(X, Y, 'ok');
	plot(xx, yy, 'o', 'Color', [0.6 0.6 0.6]);

	% get a 1d gaussian
	gauss1d = normpdf(-conePts:conePts, xo, coneSigma);
	% into a 2d gaussian
	coneRF = gauss1d' * gauss1d;

	% the multiplying and dividing pts is a little sloppy but works..
	RFpts = (-conePts:conePts)/pts;

	% place a receptive field at each cone;
	figure('Name', 'Cone Receptive Fields'); 
	axis equal; hold on;
	im = cell(1 + numel(xx) + numel(X), 1);
	% center cone
	im{1,1} = surf('XData', pts*(xo+RFpts), 'YData', pts*(yo+RFpts),... 
		'ZData', coneRF);
	% diagonals - will be empty for 1 ring mosaics
	for ii = 1:numel(xx)
		im{1 + ii, 1} = surf('XData', pts*(xx(ii) + RFpts),... 
			'YData',  pts * (yy(ii) + RFpts), 'ZData', coneRF);
	end
	% off diagonals
	for ii = 1:numel(X)
		im{ii + numel(xx) + ii, 1} = surf('XData', pts*(X(ii) + RFpts),... 
			'YData', pts * (Y(ii) + RFpts), 'ZData', coneRF);
	end
	shading('interp');

	surfaces = findall(gcf, 'Type', 'Surface');

	xmin = 0; ymin = 0;
	for ii = 1:size(surfaces, 1)
		if min(surfaces(ii,1).XData) < xmin
			xmin = min(surfaces(ii, 1).XData);
		end
		if min(surfaces(ii,1).YData) < ymin
			ymin = min(surfaces(ii,1).YData);
		end
	end
	xshift = median(diff(surfaces(1,1).XData));
	yshift = median(diff(surfaces(1,1).YData));
	m = numel(surfaces(1,1).XData);
	n = numel(surfaces(1,1).YData);
	% assign all cones to a single grid
	newGrid = zeros(2*abs(xmin)*xshift + 1, 2*abs(ymin)*yshift + 1);
	[M, N] = size(newGrid);
	m0 = M/2; n0 = N/2;

	newGrid(m0-m/2:m0+m/2, n0-n/2:n0+n/2) = coneRF;


	newRF = repmat(padarray(coneRF, [3 0], , [3 1]);