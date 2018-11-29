function iplPercent = clipStrataCData(neuron, INL, GCL, border)
    % CLIPSTRATACDATA
    %
    % Description:
    %   Clip colormap at a certain point around IPL
    %
    % Syntax:
    %   iplPercent = clipStrataCData(neuron, INL, GCL, margin);
    %
	% Inputs:
	%	neuron 		Patch or vertices matrix (from StructureAPI.render)
	%	INL         sbfsem.builtin.INLBoundary
    %   GCL         sbfsem.builtin.GCLBoundary
    %   border      margin before clipping (default = 10%)
    %
    % Output:
    %   iplPercent  Face vertex CData
    %
    % See also:
    %   GETSTRATACDATA, SBFSEM.CORE.BOUNDARYMARKER, RENDERAPP
    %
    % History:
    %   28Nov2018 - SSP
    % ---------------------------------------------------------------------
    
    if nargin < 4
        border = 0.1;
    elseif border > 1
        border = border/100;
    end

    iplPercent = getStrataCData(neuron, INL, GCL);

    % Clip the values exceeding the border regions
    iplPercent(iplPercent < -border) = -border;
    iplPercent(iplPercent > 1+border) = 1+border; 
    
    % This was set within getStrataCData without clipping. Update here
    if isa(neuron, 'matlab.graphics.primitive.Patch')
        set(neuron, 'FaceVertexCData', iplPercent);
    end