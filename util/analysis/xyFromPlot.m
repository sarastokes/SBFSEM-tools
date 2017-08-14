function [xy, ind] = xyFromPlot(data)
	% XYFROMPLOT  Get new xy values after axon removed
	%
	% INPUT: data		gco
	%
	% 12Aug2017 - SSP - created

	if ~isa(data, 'matlab.graphics.chart.primitive.Line')
		return;
	end

	xy = [get(data, 'XData')', get(data, 'YData')'];
	
	[xy, ind] = rmNaN(xy);

