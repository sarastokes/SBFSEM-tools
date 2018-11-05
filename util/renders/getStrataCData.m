function iplPercent = getStrataCData(neuron, INL, GCL)
	% GETSTRATACDATA
    %
    % Description:
    %   Assign vertex color data based on percent IPL stratification
	%
	% Inputs:
	%	neuron 		Patch or vertices matrix (from StructureAPI.render)
	%	INL         sbfsem.builtin.INLBoundary
    %   GCL         sbfsem.builtin.GCLBoundary
    %
    % Output:
    %   iplPercent  Face vertex CData
	%
	% History:
	%	3Nov2018 - SSP
	% ------------------------------------------------------------------

	if isa(neuron, 'matlab.graphics.primitive.Patch')
		V = neuron.Vertices;
		applyCData = true;
	else
		V = neuron;
		applyCData = false;
	end

	[X, Y] = meshgrid(GCL.newXPts, GCL.newYPts);
	vGCL = interp2(X, Y, GCL.interpolatedSurface,...
		V(:, 1), V(:, 2));

	[X, Y] = meshgrid(INL.newXPts, INL.newYPts);
	vINL = interp2(X, Y, INL.interpolatedSurface,...
		V(:, 1), V(:, 2));

	iplPercent = (V(:, 3) - vINL) ./ ((vGCL-vINL)+eps);

	if applyCData
		set(neuron, 'FaceVertexCData', iplPercent);
	end
end