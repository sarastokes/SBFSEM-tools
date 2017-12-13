function boundingBox = xyzr2bb(xyz, r)
	% XYZR2BB  Get bounding box encompassing all points  
	% Inputs:
	%	xyz 		[Nx3] points
	% Optional inputs:
	%	r 			Radius (if xyz is disc center)
	% Output:
	%	boundingBox 	[xmin xmax ymin ymax]
	%
	% 8Dec2017 - SSP
    %
    % See also GROUPBOUNDINGBOX
    
    if iscell(xyz)
        xyz = xyz{:};
    end

	if nargin < 2
		boundingBox = [	floor(min(xyz(:,1))),...
                        ceil(max(xyz(:,1))),...
						floor(min(xyz(:,2))),...
                        ceil(max(xyz(:,2)))];
	else
		assert(isequal(size(xyz,1), size(r,1)),...
			'xyz2boundingBox - 1st dimension of xyz and r must match');
		boundingBox = [ floor(min(xyz(:,1) - r)),... 
						ceil(max(xyz(:,1) + r)),...
						floor(min(xyz(:,2) - r)),... 
						ceil(max(xyz(:,2) + r))];
	end