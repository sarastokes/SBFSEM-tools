function pts = rect2pts(rect)
	% RECT2PTS  Convert to Matlab's position to points
	% Input:
	%	rect 		[x y w h]
	% Output:
	%	pts 		[x y x+w y+h]
	%
	% 29Nov2017 - SSP

	pts = [rect(1), rect(2), rect(1)+rect(3), rect(2)+rect(4)];