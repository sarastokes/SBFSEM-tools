%% IPL depth tutorial
%
% History:
%   20190307 - SSP - wrote for JMO
%   20190728 - SSP - added to tutorials folder
% -------------------------------------------------------------------------

c10747 = Neuron(10747, 'i');

% Creates a vector of numbers starting at 0 and increasing by 0.04 until 1.
binLocations = 0:0.04:1;  % every 4%
% So every 2% would be:
% binLocations = 0:0.02:1;

% Suppress the standard plot, since we'll be making our own
[~, stats] = iplDepth(c10747,... 
    'BinLocations', binLocations, 'Plot', false);
% Stats returns the statistics as well as the histogram info to plot
stats.bins      % Center value of each bin
stats.counts    % Number of annotations in each bin

% If you'd like to recalculate the mean and other stats omitting parts like
% the bipolar cell axons, you can use 'openvar' to get the numbers
%% Create the figure

% binLocations specifies the edges of the bins, so the number of values
% returned will always be 1 less than the number of bin edges For this
% reason, you'll need to plot with the bin centers, not the bin locations.
figure();

plot(stats.bins, stats.counts, 'Marker', 'o', 'Color', [0, 0, 0]);
xlabel('IPL Depth (%)')
ylabel('Number of annotations');

% Here I set the ticks to every 5%, but you could modify it with syntax
% similar to specifiying the bin locations.
set(gca, 'XTick', 0:0.05:1);

% I like the stratification to be expressed in %, so I'm just multiplying
% the x-axis labels by 100
set(gca, 'XTickLabels', 0:5:100);

% Some other axis settings that are just a matter of preference
set(gca, 'Box', 'off', 'TickDir', 'out');
grid on;