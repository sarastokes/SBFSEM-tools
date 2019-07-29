%% 20190717
% Synapse Sphere tutorial (brief version, just essential info) 
% --

% First import the neuron with synapses
c121 = Neuron(121, 't', true);
% and render
c121.render();


% SYNAPSE SPHERE COMMANDS
%   'ax' is the axes handle you want to plot the synapses to. 
%   'gca' is the current axis (aka last figure you clicked on)
%   'MarkerSize' (or you can use the old command 'SF') is the sphere radius 
%       in microns. Default is 500 nm. 
%   'FaceColor' is the synapse sphere color (RGB specified from 0-1) 
%   'FaceAlpha' is the synapse sphere transparency (0 is invisible, 1 is solid)


% To render all synapses of a single type:
synapseSphere(c121, 'RibbonPost',...
    'ax', gca,...
    'MarkerSize', 0.5,...
    'FaceColor', [0, 0, 0],...
    'FaceAlpha', 1);

% You can also specify specific synapse IDs. There is a tutorial on this on
% Slack dated 20190417, but long story short, you just need to include the
% synapse IDs and they must be child structures of the neuron provided in
% the first argument. Specify the synapse IDs inside a pair of brackets []
% as shown below. This would replace 'RibbonPost'

synapseSphere(c121, [39171, 39168, 39167],...
    'ax', gca,...
    'MarkerSize', 1,...
    'FaceColor', [0 1 1],...
    'FaceAlpha', 1);