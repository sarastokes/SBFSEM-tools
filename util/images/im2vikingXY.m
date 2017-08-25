function fac = im2vikingXY(xy, vikingXY)
	% IM2VIKINGXY  Returns im -> viking factor
	
	if size(xy,2) > 1
		x = median(xy(1,:));
		y = median(xy(2,:));
	end
	
	fac = vikingXY - [x y];
    fac = fac';
	
end