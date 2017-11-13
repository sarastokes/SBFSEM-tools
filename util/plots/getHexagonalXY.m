function [x,y] = getHexagonalXY(direction, n, pt, spacing)
	% GETHEXAGONALXY  Get point on hexagonal grid
	% INPUTS:
	%	pt 			[xo yo] reference point
	%	direction 	(nw, ne, sw, se, e, w)
	%	n 			how many steps away
	%	spacing 	space between each point
	% OUTPUT:
	%	xy 			coordinates of new point

	if nargin < 4
		spacing = 0.5;
	end
	if nargin < 3
		pt = [0 0];
	end
	if nargin < 2
		n = 1;
	end

	switch lower(direction)
	case {'nw', 'northwest'}
		x = pt(1) - 0.5*n*spacing;
		y = pt(2) + n*spacing;
	case {'ne', 'northeast'}
		x = pt(1) + 0.5*n*spacing;
		y = pt(2) + n*spacing;
	case {'east', 'e'}
		x = pt(1) + n*spacing;
		y = pt(2);
	case {'southeast', 'se'}
		x = pt(1) + 0.5*n*spacing;
		y = pt(2) - n*spacing;
	case {'southwest', 'sw'}
		x = pt(1) - 0.5*n*spacing;
		y = pt(2) - n*spacing;
	case {'west', 'w'}
		x = pt(1) - n*spacing;
		y = pt(2);
	otherwise
		fprintf('did not match direction: %s\n', direction);
	end