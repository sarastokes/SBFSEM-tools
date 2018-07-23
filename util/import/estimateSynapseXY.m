function synapseNodes = estimateSynapseXY(neuron, synapseNodes)
    % ESTIMATESYNAPSEXY
    %
    % Description:
    %   A Neuron method for estimating synapse location.
    %
    % Input:
    %   neuron      Neuron class
    % Output:
    %   ID          Synapse location IDs
    %   xyOffset    New X, Y values
    %
    % Notes:
    %   Synapses don't have X and Y data. To make renders constant 
    %   despite varying transforms, in NeitzInferiorMonkey, X and Y, rather
    %   than VolumeX and VolumeY are used to compute XYZum. This means
    %   synapse locations are no longer in register with cell annotations.
    %   This function is meant to be a temporary fix.
    %
    % See also:
    %   NEURON, NEARESTNODES, FASTEUCLID3D, NEURON/GETSYNAPSES
    %
    % History:
    %    23Jul2018 - SSP
    % ---------------------------------------------------------------------
    
    if ~strcmp(neuron.source, 'NeitzInferiorMonkey')
        return
    end
    
    % Get locations of synapse nodes, without transform.
    synapseXYZ = synapseNodes{:, {'VolumeX', 'VolumeY', 'Z'}};
    % Get locations of neuron nodes, without transform.
    nodeXYZ = neuron.nodes{:, {'VolumeX', 'VolumeY', 'Z'}};
    
    
    
    synapseIDs = synapseNodes{:, 'ID'};
    nodeIDs = neuron.nodes{:, 'ID'};
    
    % Convert to microns for comparison
    synapseXYZ = bsxfun(@times, synapseXYZ,...
        (neuron.volumeScale./1e3));
    nodeXYZ = bsxfun(@times,...
        [nodeXYZ(:, 1), nodeXYZ(:, 2), nodeXYZ(:, 3)],...
        (neuron.volumeScale./1e3));
    
    ind = zeros(size(synapseIDs));
    for i = 1:numel(synapseIDs)
        zRow = neuron.nodes.Z == synapseNodes.Z(i);
        [~, ind(i)] = min(fastEuclid2d(synapseXYZ(i,1:2), nodeXYZ(zRow, 1:2)));
        % [~, ind(i)] = min(fastEuclid3d(synapseXYZ(i,:), nodeXYZ));
    end
    
    nearestIDs = nodeIDs(ind);
    
    T  = neuron.nodes(ismember(nearestIDs, neuron.nodes.ID), :);
    XY = [T.X-T.VolumeX, T.Y-T.VolumeY];
    
    % Apply to synapse table
    synapseNodes.X = synapseNodes.VolumeX + XY(:, 1);
    synapseNodes.Y = synapseNodes.VolumeY + XY(:, 2);
