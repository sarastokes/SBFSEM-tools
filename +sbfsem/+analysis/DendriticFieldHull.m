classdef DendriticFieldHull < sbfsem.analysis.NeuronAnalysis
% DENDRITICFIELDHULL
%
%   Syntax:
%       obj = sbfsem.analysis.DendriticFieldHull(neuron, xyz, scatterPlot)
%
%   Inputs:
%      neuron           neuron object
%   Optional:  
%       xyz             dendrites to use in analysis
%                       use if removing axons, leave empty [] if not
%       scatterPlot     plot annotations as scatterplot, default = render
%   Output:
%       d               structure containing stats
%       []              creates a figure w/ convhull, centroid, dendrites
%
%   NOTES:  Analysis is not projected onto plane calculated from depth
%           markers. This should be ok for smaller neurons but will
%           need to be corrected at some point for wide-field cells
%
%   History:
%       Aug2017 - SSP
%       18Feb2019 - SSP - Fixed hull coordinates and added centroid
%       28Nov2020 - SSP - Made render default and scatter plot 3rd argument
% -------------------------------------------------------------------------

    properties
        % This often requires manually removing an axon or clipping out
        % processes on one side of a bipolar cell. This property stores the
        % final cell structure used in analysis. Right now, the structure
        % is automatically saved, this may become optional in the future.
        dendrites
        axHandle
    end

    properties (Constant = true, Hidden = true)
        DisplayName = 'DendriticFieldHull'
    end

    methods
        function obj = DendriticFieldHull(neuron, xyz, scatterPlot)
            validateattributes(neuron, {'sbfsem.core.NeuronAPI'}, {});
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            if nargin < 2 || isempty(xyz)
                T = obj.target.getCellNodes;
                xyz = T.XYZum;
            end

            if nargin < 3
                scatterPlot = false;
            end
            obj.dendrites = xyz;
            obj.doAnalysis(xyz);
            obj.plot(scatterPlot);
        end

        function doAnalysis(obj, xyz)
            % DOANALYSIS  Borrows code from analyzeDF function
            % Optional inputs:
            %   xyz     Overrides xyz values in obj.dendrites

            % This allows the analysis to be called individually with new
            % underlying data.
            if nargin < 2
                xyz = obj.dendrites;
            end

            % For most neurons this is ok. Some of the larger cells on
            % the slope may need to be projected onto a more accurate plane.
            % Eventually that option will be included automatically.
            xy = xyz(:,1:2);

            k = convhull(xy(:,1), xy(:,2));
            obj.data.hullArea = polyarea(xy(k,1), xy(k,2));
            obj.data.hull = xy(k, :);
            obj.data.centroid = polygonCentroid(xy(k, 1), xy(k, 2));

            % Print results
            fprintf('Area is %.2f\n', obj.data.hullArea);
            fprintf('Centroid is %.2f, %.2f\n', obj.data.centroid);

            % Save the dendrites used
            obj.dendrites = xyz;
        end

        function plot(obj, scatterPlot)
            if nargin < 2
                scatterPlot = false;
            end
            % Render or Scatter plot of the annotations
            if scatterPlot
                ax = axes('Parent', figure());
                hold(ax, 'on');
                axis(ax, 'equal');
                scatter(obj.dendrites(:, 1), obj.dendrites(:, 2), '.k');
            else
                h = obj.target.render('FaceColor', [0.1 0.1 0.1], 'FaceAlpha', 0.6);
                ax = h.Parent;
            end

            % Decide Z location for convex hull
            soma = obj.target.getSomaXYZ();
            if abs(max(obj.dendrites(:, 3)) - soma(3)) >= abs(min(obj.dendrites(:, 3)) - soma(3))
                Z = max(obj.dendrites(:, 3)) + zeros(size(obj.data.hull, 1), 1);
            else
                Z = min(obj.dendrites(:, 3)) + zeros(size(obj.data.hull, 1), 1);
            end

            % Plot the surrounding convex hull
            patch(ax, 'XData', obj.data.hull(:, 1), 'YData', obj.data.hull(:,2),...
                'ZData', Z, 'FaceColor', [0, 0.447, 0.741],... 
                'FaceAlpha', 0.3, 'Tag', num2str(obj.ID));
            plot3(ax, obj.data.centroid(1), obj.data.centroid(2), Z(1),... 
                'r', 'Marker', 'p', 'MarkerSize', 9);
            title(ax, sprintf('c%u - area = %.2f um^2, centroid = %.2f,%.2f',...
                obj.ID, obj.data.hullArea, obj.data.centroid));
            obj.axHandle = ax;
        end
    end
end
