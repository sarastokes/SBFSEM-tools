function mat = rotateZ(row, col, ang)
	% ROTATEZ  Generates rotation matrix 
	% like rotz in phase array system toolbox
	% 
	% 15Aug2017 - SSP - created
	fh = figure();
    ax = axes('Parent', fh);
    ln = line(row, col, 'Parent', ax);
    if isnumeric(ang)
        rotate(ln, [0 0 1], ang);
    end
    mat = [ln.XData; ln.YData];
    delete(fh);
end