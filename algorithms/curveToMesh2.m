function FV = curveToMesh2(curve, radius, nCorners)
% CURVETOMESH  Create a mesh surrounding a 3D curve
%
% 	FV = curveToMesh2(CURVE)
%	Computes the vertices and faces of the mesh surrounding the specified
%	curve vertices
%
%	FV = curveToMesh2(CURVE, THICKNESS);
%
%	FV = curveToMesh2(CURVE, THICKNESS, NCORNERS)
%
%
% See also: 
%	curve2mesh, gencyl, plot3t
%
% History:
%	1Jan2018 - SSP - modifed from geom3d toolbox's curveToMesh.m
%				     added variable radius, no loop, output options
%
% -------------------------------------------------------------------------
	if nargin < 3
		nCorners = 8;
	end

	nNodes = size(curve, 1);
	nVerts = nNodes * nCorners;
	vertices = zeros(nVerts, 3);
    
    
	% Create reference corners that will be rotated, translated, and
	% multiplied by the node's radius
	t = linspace(0, 2*pi, nCorners+1)';
	t(end) = [];
	baseCorners = [cos(t), sin(t), zeros(size(t))];

	for i = 1:nNodes
		% Coordinate of current node
		node = curve(i,:);

		% Compute local tangent vector
		iNext = mod(i, nNodes) + 1;
		tangentVector = normalizeVector3d(curve(iNext,:)-node);

		% Convert to spherical coordinates
		[theta, phi, ~] = cart2sph2(tangentVector);

		% Apply transformation to place corners around current node
		rotY = createRotationOy(theta);
		rotZ = createRotationOz(phi);
		trans = createTranslation3d(node);
		transformMatrix = trans * rotZ * rotY;
		corners = transformPoint3d(radius(i) * baseCorners,...
			transformMatrix);

		% Concatenate with other corners
		vertices((1:nCorners) + (i-1) * nCorners, :) = corners;
	end

	% Indices of vertices
	inds = (1:nVerts)';
	add1 = repmat([ones(nCorners-1, 1) ; 1-nCorners], nNodes, 1);

	% Generate faces
	faces = [inds ...
	    mod(inds + add1 - 1, nVerts) + 1 ...
	    mod(inds + nCorners + add1 - 1, nVerts) + 1 ...
	    mod(inds + nCorners - 1, nVerts) + 1];

	faces(1:end-nCorners, :) = [];

	FV = struct('faces', faces, 'vertices', vertices);