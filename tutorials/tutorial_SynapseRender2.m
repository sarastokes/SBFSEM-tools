% Synapse Sphere tutorial (brief version, just essential info) 
%
% History:
%   17Jul2019 - SSP 
%   24Apr2020 - SSP - Increased synapse sizes, changed colors
% -------------------------------------------------------------------------

% First import the neuron with synapses
c121 = Neuron(121, 't', true);
% and render
c121.render('FaceColor', [0.62, 0.8, 0.8], 'FaceAlpha', 0.6);


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
    'MarkerSize', 1,...
    'FaceColor', rgb('emerald'),...
    'FaceAlpha', 0.9);

% You can also specify specific synapse IDs. There is a tutorial on this on
% Slack dated 20190417, but long story short, you just need to include the
% synapse IDs and they must be child structures of the neuron provided in
% the first argument. Specify the synapse IDs inside a pair of brackets []
% as shown below. This would replace 'RibbonPost'

synapseSphere(c121, [39171, 39168, 39167],...
    'ax', gca,...
    'MarkerSize', 1,...
    'FaceColor', rgb('light red'),...
    'FaceAlpha', 1);

% Sometimes makes synapses easier to see if not shiny
material dull; 