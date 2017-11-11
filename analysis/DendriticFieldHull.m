classdef DendriticFieldHull < NeuronAnalysis

    properties
        % This often requires manually removing an axon or clipping out
        % processes on one side of a bipolar cell. This property stores the
        % final cell structure used in analysis. Right now, the structure
        % is automatically saved, this may become optional in the future.
        dendrites
    end

    properties (Constant = true, Hidden = true)
        DISPLAYNAME = 'DendriticFieldHull'
    end

    methods
        function obj = DendriticFieldHull(neuron, xyz)
            validateattributes(neuron, {'Neuron'}, {});
            obj@NeuronAnalysis(neuron);
            if nargin < 2
                row = strcmp(neuron.dataTable.LocalName, 'cell');
                xyz = neuron.dataTable.XYZum(row,:);
            end
            obj.dendrites = xyz;
            obj.doAnalysis();
            obj.visualize();
        end

        function doAnalysis(obj, xyz)
          % DOANALYSIS  Borrows code from analyzeDF function

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
