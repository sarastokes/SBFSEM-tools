function [X, Y, xyOffset] = xyShift(neuron, sections, X, Y)
    % XYSHIFT
    %
    % Description:
    %   Calculate XY offset between two sections, apply to vitread sections
    %
    % Inputs:
    %	neuron 			Neuron object
    %	sections 		2 consecutive sections to bridge
    % Optional inputs:
    %	X               Working X-coordinates
    %	Y               Working Y-coordinates
    %
    % Outputs:
    %   X               Adjusted X-coordinates
    %   Y               Adjusted Y-coordinates
    %   xyOffset        Amount of XY offset
    %
    % Notes:
    % 	Right now this is a quick hack for the smidget paper. This method
    % 	should not be used routinely. The danger in computing all these
    % 	neuron-specific offsets is that the most vitread sections of each
    % 	neuron will be living in slightly different coordinate systems.
    % 	This effect is minimal for midget bipolar cells with a single
    % 	consistent axon spanning the sections. For wide-field dendrites
    % 	with naturally large offsets between sections, the offsets would
    % 	cause significant issues.
    %
    % 29Dec2017 - SSP
    % ---------------------------------------------------------------------

    % The sclerad section is section1
    section1 = max(sections);
    section2 = min(sections);

    % If no working XY stack provided
    if nargin < 3
        X = neuron.nodes.VolumeX;
        Y = neuron.nodes.VolumeY;
    end

    % Get annotations at section1
    row1 = neuron.nodes.Z == section1;
    row2 = neuron.nodes.Z == section2;

    if nnz(row1) == 0 || nnz(row2) == 0
        fprintf('No annotations bridging %u-%u gap\n', section1, section2);
    elseif nnz(row1) > 1 || nnz(row2) > 1
        fprintf('Mutliple annotations: %u on %u, %u on %u\n',...
            nnz(row1), section1, nnz(row2), section2);
    else
        % Calculate the offset
        xOffset = X(row1,:) - X(row2,:);
        yOffset = Y(row1,:) - Y(row2,:);
        fprintf('Applying offset: X = %.2f, Y = %.2f\n', xOffset, yOffset);
        % Apply the offset to all vitread sections
        vitread = neuron.nodes.Z <= section2;
        X(vitread) = X(vitread) + xOffset;
        Y(vitread) = Y(vitread) + yOffset;
    end
    
    % In the future, I'd like to store the offsets applied with the neuron
    if nargout == 3
        xyOffset = [xOffset, yOffset];
    end