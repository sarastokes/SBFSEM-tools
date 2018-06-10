function IDs = minmaxNodes(neuron, dir)
    % MINMAXNODES
    %
    % Description:
    %   Returns the most vitread and sclerad node location IDs.
    %
    % Syntax:
    %   IDs = minmaxNodes(neuron);
    %   IDs = minmaxNodes(neuron, 'min');
    %
    % Input:
    %   neuron      Neuron object
    %   dir         'min', 'max'. If not specified, both are returned
    %
    % Output:
    %   IDs         [most vitread ID, most sclerad ID]
    %
    % Note:
    %   If more than one node is the minimum or maximum, picks one
    %   arbitrarily. A warning message will be displayed if this occurs.
    %
    % History:
    %   5Jun2018 - SSP
    % ---------------------------------------------------------------------

	tmin = neuron.nodes(neuron.nodes.Z == min(neuron.nodes.Z), :);
	tmax = neuron.nodes(neuron.nodes.Z == max(neuron.nodes.Z), :);
    
    maxID = tmax.ID;
    if numel(maxID) > 1
        fprintf('found %u max nodes\n', numel(maxID));
        maxID = maxID(1);
    end
    
    minID = tmin.ID;
    if numel(minID) > 1
        fprintf('found %u min nodes\n', numel(minID));
        minID = minID(1);
    end
    
    IDs = [minID, maxID];
    
    if nargin == 2        
        switch dir
            case 'min'
                IDs = IDs(1);
            case 'max'
                IDs = IDs(2);
        end
    end
    
