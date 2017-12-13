function [m, n] = bb2size(boundingBox)
	%BB2SIZE  Returns size of bounding box

	m = boundingBox(2)-boundingBox(1);
	n = boundingBox(4)-boundingBox(3);