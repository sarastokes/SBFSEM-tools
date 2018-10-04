% Tortuosity analysis tutorial
% 3Oct2018 - SSP


c4781 = Neuron(4781, 'i');

% A replacement for Tulip I've been working on recently. Tulip is fine too
GraphApp(c4781);

% In either GraphApp (by selecting Data Cursor mode) or in Tulip, find the
% location IDs of the first and last node of the branch you want to analyze
d = tortuosity(c4781, 178736, 193790, 'Plot', true); % 1.11

d = tortuosity(c4781, 178614, 192925, 'Plot', true); % 1.13

% An example of nodes that are not connected and need to be investigated
d = tortuosity(c4781, 388706, 389069, 'Plot', true);

% GraphApp has features useful for this analysis. The "Color segments"
% option shows the different segments of connected annotations. Each
% segment gets a different color. So a change in color could just be a
% small 1-2 annotation branch, or it could mean two annotations aren't
% connected. If you're getting an error saying two nodes are not connected,
% checking out the location IDs around a color change will be helpful.
% Turning off "Show surface" makes it easier to see the segments.

% One limitation of the current analysis is the resolution in the Z axis.
% For widefield neurons, calculating the tortuosity by taking only the XY
% dimensions into account seems okay. 2D is the default, but you can
% decide for yourself by comparing with the 3D
d = tortuosity(c4781, 178736, 193790, 'Plot', true, 'Dim', 3); % 1.07
