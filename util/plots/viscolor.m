function circleGroup = viscolor(circleGroup, co)
	% Set the color of a viscircles entity
	%
	% 3Aug - SSP - created

		for ii = 1:numel(circleGroup.Children)
			circleGroup.Children(ii).Color = co;
		end