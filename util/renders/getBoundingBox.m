function boundingBox = getBoundingBox(neuron, useMicrons)
    % GETBOUNDINGBOX  
    %
    % Description:
    %   Calculates extent in xy-plane 
    %
    % Syntax:
    %   boundingBox = getBoundingBox(neuron, useMicrons);
    %
    % Inputs:
    %   neuron                  Neuron object
    % Optional inputs:
    %   useMicrons  [true]      microns or pixels  
    %   
    % Outputs:
    %   boundingBox     [xmin ymin xmax ymax]
    % -------------------------------------------------------------
    if nargin < 2
        useMicrons = true;
        disp('Set units to microns');
    else
        assert(islogical(useMicrons), 'useMicrons is t/f');
    end

    if useMicrons
        xyz = neuron.nodes.XYZum;
        r = neuron.nodes.Rum;
    else
        xyz = [neuron.nodes.VolumeX, neuron.nodes.VolumeY];
        r = neuron.nodes.Radius;
    end
    boundingBox = [min(xyz(:,1) - r), max(xyz(:,1) + r),...
        min(xyz(:,2) - r), max(xyz(:,2) + r)];  

    % Now check for closed curves
    neuron.getGeometries();
    if ~isempty(neuron.geometries)
        disp('Including closed curves');
        % TODO add close curve geometries
    end
end