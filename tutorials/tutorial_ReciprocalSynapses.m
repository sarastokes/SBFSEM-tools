%% Reciprocal synapses 
%
% History:
%   20181115 - SSP - wrote for ASB
%   20190728 - SSP - moved to tutorials folder
% -------------------------------------------------------------------------

c6131 = Neuron(6131, 'r', true);
% Import pre- and post-synaptic data
x = sbfsem.analysis.ReciprocalSynapses(c6131);
% Run analysis
x.doAnalysis();
% View analysis
openvar('x');
% Click on the 'preSynData', 'postSynData' and 'data' for the presynapse,
% postsynapse and final result tables
