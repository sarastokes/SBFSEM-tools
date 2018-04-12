function [x, y] = catmullRomSpline(Px, Py, N)
	% CATMULLROMSPLINE
	%
	% Description:
	% 	Fits control points with a Catmull Rom spline.
	%
	% Inputs:
	%	Px 		X points (vector)
	%	Py 		Y points (vector)
	%	N 		Number of spline points (integer, default = 100)
	% Outputs:
	%	x 		X points
	%	y 		Y pointss
	%
	% History:
	%	15Nov2017 - SSP
	% 	10Apr2018 - SSP - option to specify # of spline points
	% ------------------------------------------------------------------
	if nargin == 3
		N = ceil(N);
	else
		N = 100;
	end
	T = 0;
	x = []; y = [];

	for i = 1:length(Px)-3
		[xvec, yvec] = evaluate([Px(i), Py(i)], [Px(i+1), Py(i+1)],...
			[Px(i+2), Py(i+2)], [Px(i+3), Py(i+3)], T, N);
		x = [x, xvec];
		y = [y, yvec];
	end
end

function [xvec, yvec] = evaluate(P0, P1, P2, P3, T, N)
	xvec = []; yvec = [];

	u = 0;
	[xvec(1), yvec(1)] = getNext(P0, P1, P2, P3, T, u);
	du = 1/N;
	for i = 1:N
		u = i*du;
		[xvec(i+1), yvec(i+1)] = getNext(P0, P1, P2, P3, T, u);
	end
end

function [xy, yt] = getNext(P0, P1, P2, P3, T, u)
	s = (1-T)./2;

	MC=[-s     2-s   s-2        s;
	    2.*s   s-3   3-(2.*s)   -s;
	    -s     0     s          0;
	    0      1     0          0];

	GHx = [P0(1); P1(1); P2(1); P3(1)];
	GHy = [P0(2); P1(2); P2(2); P3(2)];

	U = [u.^3 	u.^2 	u 	1];

	xy = U*MC*GHx;
	yt = U*MC*GHy;
end