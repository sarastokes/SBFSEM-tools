function neuron = addAnalysis(neuron, analysis, overwrite)
    % ADDANALYSIS  Append or update an analysis
    % ----------------------------------------------------------

    if nargin < 3 
        overwrite = false;
    end

    assert(isa(analysis, 'sbfsem.analysis.NeuronAnalysis'),...
        'Input must be of class NeuronAnalysis');

    % Analysis holds a reference to target neuron
    if isprop(analysis, 'target') && ~isempty(analysis.target)
        analysis.target = [];
    end

    if isKey(neuron.analysis, analysis.DisplayName)
        if overwrite
            neuron.analysis(analysis.DisplayName) = analysis;
        else
            fprintf('Existing %s, call fcn w/ overwrite enabled\n',... 
                analysis.DisplayName);
            return;
        end
        % dialog to overwrite existing
    else
        neuron.analysis(analysis.DisplayName) = analysis;
    end

    fprintf('Added %s analysis\n', analysis.DisplayName);
end
