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
    plot(b(2:end)-(b(2)-b(1))/2, a, '-ob', 'LineWidth', 1);
    xlabel('IPL Depth (%)');
    ylabel('Synapse Count');
    
