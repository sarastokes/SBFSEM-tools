function SA = surfaceArea(neuron)
	% SURFACEAREA
	%
	% Description:
	%	Rudimentary calculation of neuron surface area
	%
	% Syntax:
	%	SA = surfaceArea(neuron)
    %
    % Input:
    %   neuron      StructureAPI object
    % Output:
    %   SA          Surface area (microns2)
	%
	% History:
	%	14Oct2018 - SSP
    % ---------------------------------------------------------------------

	% Volume dimensions (microns)
	x = neuron.volumeScale() * 1e-3;

	% Circumference (microns)
	C = pi * 2 * sum(neuron.nodes.Rum);
	% Surface area (microns2)
	SA = x(3) * C;

	fprintf('\tc%u surface area = %.3g mm2\n',...
		neuron.ID, SA);

end