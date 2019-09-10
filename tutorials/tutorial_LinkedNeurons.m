% Linked neuron tutorial
% 4Jun2018 - SSP
% 10Sep2019 - SSP - Updated and includes getAllLinkedNeurons
% -------------------------------------------------------------------------

% Import a neuron and synapses
c13525 = Neuron(13525, 'r', true);


% Get the linkedIDs (the StructureID of the linked neuron) and the
% synapseIDs (the StructureID of the synapse of c13525).
% WARNING: This is slow as it requires querying each synapse Structure
% individually.
[linkedIDs, synapseIDs, synapseXYZ] = getLinkedNeurons(c13525, 'ConvPost');

% 16Apr2019 - getLinkedNeurons now outputs a table if only 1 output
% is specified
T = getLinkedNeurons(c13525, 'ConvPost');

% Open the table in Matlab's variable viewer
openvar('T');

% Note: Some entries in 'LinkedID' will be NaN. This occurs when there is
% no post/pre-synaptic neuron linked to a synapse.

%% To get all linked neurons of all synapse types:
T = getAllLinkedNeurons(c13525)