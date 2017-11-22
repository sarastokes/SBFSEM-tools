function boundingBox = groupBoundingBox(annotations)
	% GROUPBOUNDINGBOX  Finds bounds for a group of annotations
	% 	Input:
	%		annotations 		closed curves or discs
	%	Output:
	%		

	assert(isa(annotations, 'sbfsem.core.Annotation'),...
		'Input must be Annotation(s)');

	allBounds = vertcat(annotations.localBounds);
    boundingBox = [ min(allBounds(:,1)), max(allBounds(:,2)),... 
                    min(allBounds(:,3)), max(allBounds(:,4))];
            