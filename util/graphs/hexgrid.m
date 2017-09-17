% HEXGRID  Hex coordinates from compass directions

	% these are like unit vectors
	% east = [1, 0, -1];
	% northeast = [0, 1, -1];
	% northwest = [-1, 1, 0];
	% west = [-1, 0, 1];
	% southwest = [0, -1, 1];
	% southeast = [1, -1, 0];

	directions = {'nw', 'ne', 'e', 'se', 'sw', 'w'};

	radius = 0.9; gap = 0.1;
	coneSigma = radius/1.5;
	spacing = 2*(radius + gap);

	pts = 100;
	conePts = pts/2 * radius;
	coneSigma = pts * coneSigma;

	yo = 0; xo = 0;

	numX = 6;
	numY = 15;
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

	figure; hold on;
	plot(xo, yo, 'ok');
	plot(X(:), Y(:), 'ok');
	plot(xx, yy, 'o', 'Color', [0.6 0.6 0.6]);

	X = X(:); Y = Y(:);
	[newX, newY] = meshgrid(linspace(min(X), max(X), pts*numY), linspace(min(Y), max(Y), pts*numY));
	% get a 1d gaussian
	gauss1d = normpdf(-conePts:conePts, xo, coneSigma);
	% into a 2d gaussian
	coneRF = gauss1d' * gauss1d;

	RFpts = (-conePts:conePts)/pts;
	% place it at a specific cone;
	imagesc('XData', xx(1) + RFpts, '');

