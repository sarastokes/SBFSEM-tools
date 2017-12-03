classdef DendriticFieldHull < sbfsem.analysis.NeuronAnalysis
% DENDRITICFIELDHULL
%
%   Inputs:
%      neuron           neuron object
%   Optional:  
%       xyz             dendrites to use in analysis
%                       use if removing axons
%   Output:
%       d               structure containing stats
%       []              creates a figure showing convhull and dendrites
%
%   NOTES:  Analysis is not projected onto plane calculated from depth
%           markers. This should be ok for smaller neurons but will
%           need to be corrected at some point for wide-field cells
%
%   Aug2017 - SSP

    properties
        % This often requires manually removing an axon or clipping out
        % processes on one side of a bipolar cell. This property stores the
        % final cell structure used in analysis. Right now, the structure
        % is automatically saved, this may become optional in the future.
        dendrites
    end

    properties (Constant = true, Hidden = true)
        DisplayName = 'DendriticFieldHull'
    end

    methods
        function obj = DendriticFieldHull(neuron, xyz)
            validateattributes(neuron, {'sbfsem.Neuron'}, {});
            obj@sbfsem.analysis.NeuronAnalysis(neuron);
            if nargin < 2
                T = obj.target.getCellNodes;
                xyz = T.XYZum;
            end
            obj.dendrites = xyz;
            obj.doAnalysis();
            obj.visualize();
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
          % Eventually that option will automatically be included.
          xy = xyz(:,1:2);

          k = convhull(xy(:,1), xy(:,2));
          obj.data.hullArea = polyarea(xy(k,1), xy(k,2));
          obj.data.hull = k;

          % Save the dendrites used
          obj.dendrites = xy;
        end

        function visualize(obj)
          % VISUALIZE  Plot the analysis results
          figure(); hold on;
          scatter(obj.dendrites(:,1), obj.dendrites(:,2), '.k');
          plot(obj.dendrites(obj.data.hull,1), obj.dendrites(obj.data.hull,2),...
              'b', 'LineWidth', 2);
          title(sprintf('area = %.2f um^2', obj.data.hullArea));
        end % visualize
    end % methods
end % classdef
