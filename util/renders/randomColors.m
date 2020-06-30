function rgb = randomColors(gObj, varargin)
    % RANDOMCOLORS
    %
    % Description:
    %   Randomly color all patch objects in a figure or axes
    %
    % Syntax:
    %   randomColors(gObj);
    %
    % Input:
    %   gObj            Handle to a figure or axes
    % Can also pass key/value inputs to change properties of all patches in
    % the figure/axes.
    %
    % Example:
    %   % Randomize the colors of patch objects in the current axes
    %   randomColors(gca);
    %   % Randomize the colors and set the transparency of all renders to 1
    %   randomColors(gca, 'FaceAlpha', 1);
    %
    % History:
    %   21May2019 - SSP
    % ---------------------------------------------------------------------
    
    if nargin == 0
        rgb = rand([1, 3]);
        return
    end

    patches = findall(gObj, 'Type', 'patch');
    for i = 1:numel(patches)
        set(patches(i), 'FaceColor', rand([1, 3]), varargin{:});
    end
end