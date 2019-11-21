function ipl = getSynapseStratification(neuron, synapseType)
    % GETSYNAPSESTRATIFICATION
    %
    % Syntax:
    %   ipl = getSynapseStratification(neuron, synapseType);
    % 
    % History:
    %   10Nov2019 - SSP
    % --------------------------------------------------------------------
    neuron.checkSynapses();

    xyz = neuron.getSynapseXYZ(synapseType);
    ipl = micron2ipl(xyz, neuron.source);

    if nnz(isnan(ipl)) > 0
        warning('Omitting NaNs (%u of %u)\n', nnz(isnan(ipl)), numel(ipl));
        ipl(isnan(ipl)) = [];
    end
    
    figure(); hold on;
    [a, b] = histcounts(ipl, 25);
