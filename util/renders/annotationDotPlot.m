function h = annotationDotPlot(neuron)
    % ANNOTATIONDOTPLOT
    %
    % Description:
    %   Quickly display annotation locations and links
    %
    % Syntax:
    %   h = annotationDotPlot(neuron)
    %
    % Inputs:
    %   neuron          Neuron object (sbfsem.core.StructureAPI)
    %
    % Outputs:
    %   h               Handle to dot plot line
	%
    % History:
    %   18Feb2020 - SSP
    % ---------------------------------------------------------------------
    
    xyz = neuron.getCellXYZ();
    ax = axes('Parent', figure());
    hold(ax, 'on'); grid(ax, 'on');

    h = plot3(ax, xyz(:, 1), xyz(:, 2), xyz(:, 3), '.k');