function ipl = getSynapseStratification(neuron, synapseType, varargin)
    % GETSYNAPSESTRATIFICATION
    %
    % Syntax:
    %   ipl = getSynapseStratification(neuron, synapseType, varargin);
    %
    % Inputs:
    %   neuron                  StructureAPI object
    %   synapseType             Synapse name or XYZ coordinates
    % Optional key/value inputs:
    %   PDF                     Probability distribution? (default = false)
    %   Plot                    Plot the result? (default = true)
    % 
    % History:
    %   10Nov2019 - SSP
    %   15May2020 - SSP - Added plot title, print output
    %   29Dec2020 - SSP - Added additional key/value parameters
    %   12Jan2022 - SSP - Added option for synapse XYZ coordinate input
    %   19Feb2022 - SSP - Added option to not plot the result
    % ---------------------------------------------------------------------
    
    ip = inputParser();
    addParameter(ip, 'PDF', false, @islogical);
    addParameter(ip, 'Plot', true, @islogical);
    parse(ip, varargin{:});

    if isnumeric(synapseType)
        xyz = synapseType;
        titleStr = ['c', num2str(neuron.ID)];
    else
        neuron.checkSynapses();
        xyz = neuron.getSynapseXYZ(synapseType);
        titleStr = ['c', num2str(neuron.ID), ' - ', synapseType];
    end
    ipl = micron2ipl(xyz, neuron.source);

    if nnz(isnan(ipl)) > 0
        warning('Omitting NaNs (%u of %u)\n', nnz(isnan(ipl)), numel(ipl));
        ipl(isnan(ipl)) = [];
    end
    
    if ip.Results.Plot
        figure(); hold on; grid on;
        [a, b] = histcounts(ipl, 25);
        if ip.Results.PDF
            a = a / sum(a);
            ylabel('Synapse Probability (%)');
        else
            ylabel('Synapse Count');
        end
        plot(b(2:end)-(b(2)-b(1))/2, a, '-ob',...
            'LineWidth', 1.25, 'MarkerFaceColor', [0.5 0.5 1]);
        xlabel('IPL Depth (%)');
        title(titleStr);
        figPos(gcf, 0.7, 0.7);
    end

    printStat(ipl', true);
