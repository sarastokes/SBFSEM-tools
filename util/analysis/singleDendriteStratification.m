function [iplPercent, stats] = singleDendriteStratification(neuron, locationA, locationB)
    % SINGLEDENDRITESTRATIFICATION
    %
    % Description:
    %   Returns stratification and statistics for a single branch
    %
    % Syntax:
    %   [iplPercent, stats] = singleDendriteStratification(neuron, locationA, locationB)
    %
	% Inputs:
	%	neuron 			StructureAPI object
	%	locationA 		Starting location ID
	%	locationB 		Stopping location ID
    %
    % Outputs:
    %   iplPercent  Percent IPL depth for each annotation
    %   stats       Structure containing bin centers, values and stats
    %
    % See also:
    %   MICRON2IPL
    %
    % History:
    %   13Feb2020 - SSP
    % ---------------------------------------------------------------------
    
    branchNodes = neuron.getBranchNodes(locationA, locationB);
    iplPercent = micron2ipl(branchNodes.XYZum, neuron.source);
    stats = createStatsStructure(iplPercent);
    
    
    