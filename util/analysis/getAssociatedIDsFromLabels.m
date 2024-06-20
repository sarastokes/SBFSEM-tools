
function IDs = searchLabelsReturnIDs()
    % searchLabels
    %
    % Description:
    %   Returns the cell annotation closest to the synapse annotations of a
    %   specific type.
    %
    % Syntax:
    %   nodeIDs = nearestNodes(neuron, synapseName, swc)
    %
    % Inputs:
    %   neuron          Neuron object
    %   synapseName     Target synapse name
    % Optional inputs:
    %   swc             sbfsem.io.SWC object (otherwise computed)
    %
    % History:
    %   3Jul2018 - SSP
    % ---------------------------------------------------------------------

    assert(isa(neuron, 'sbfsem.core.NeuronAPI'), 'Input a neuron object');

    xyz = neuron.getSynapseXYZ(synapseName);

    if isempty(xyz)
        nodeIDs = [];
        return
    end

    if nargin < 3 || ~isa(swc, 'sbfsem.io.SWC')
        swc = sbfsem.io.SWC(neuron);
    end

    nodeIDs = zeros(size(xyz,1), 1);

    for i = 1:size(xyz, 1)
        [~, nodeIDs(i)] = min(fastEuclid3d(xyz(i, :), swc.T.XYZ));
    end



%% Script to search for cells by label.

% Specify the volume to search:

disp(['valid options'])
disp(['     t  = TemporalMonkey2'])
disp(['     i  = InferiorMonkey'])
disp(['     nm = NasalMonkey'])
disp(['     c  = Neitzcped'])
volume = input('Please enter the volume abbreviation: ','s')
disp(['You entered: ', volume])
x = sbfsem.io.OData(volume);

% Specify the label to search. Include false if 
% not looking for an exact match

label = input('Please enter the label to be searched for: ', 's')
disp(['You entered: ', label])
idList = x.idsByLabel(label, false)
openvar('idList');