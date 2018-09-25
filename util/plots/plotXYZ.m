function ax = plotXYZ(xyz, ax)
	% PLOTXYZ
	% 
	% Description:
	%	Quick plot of a segment of annotations
	%
	% Inputs:
	%	XYZ 		[Nx3] 	Annotation locations
	% Optional inputs:
	%	ax 			Matlab axes handle
	%				Default = new figure.
	%
	% Outputs:
	%	ax 			Matlab axes handle
	%
	% History:
	%	25Sept2018 - SSP

	if nargin < 2
		ax = axes('Parent', figure('Renderer', 'painters'));
	end
	hold(ax, 'on');
	plot3(ax, xyz(:, 1), xyz(:, 2), xyz(:, 3), '-ok');
	grid(ax, 'on');
	axis(ax, 'equal', 'tight');
	xlabel(ax, 'X'); ylabel(ax, 'Y'); zlabel(ax, 'Z');
	view(ax, 3);