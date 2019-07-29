%% SYNAPSE MARKER TUTORIAL
% 
% See also: synapseMarker for 2D markers of different shapes.
%
% 28Feb2018 - SSP
% 16Jul2019 - SSP - updated
% -------------------------------------------------------------------------

%% Builtin documentation
% Check out the synapseSphere help info
help synapseSphere
% Most functions in sbfsem-tools now have decent help info, but I'm working
% to standardize it further.


%% Basic tutorial
% Import neuron with synapses and render
c6800 = Neuron(6800, 't', true);
c6800.render('FaceColor', [0.5, 0.5, 1]);

% The synapseSphere function has two required inputs: neuron and synapse
% NEURON is the Neuron object (c6800 in this case).
% SYNAPSE is the synapses to render. There are two options:

% OPTION 1: the synapse name to render (in quotes).
% For a reminder of the synapse names:
c6800.printSyn();
% The synapse names used by synapseSphere are the "Detailed names"
synapseSphere(c6800, 'ConvPost');

% OPTION 2: specific synapse IDs
% See bipolar cell input tutorial on slack board from 20190415

% The synapseSphere function has optional key/value inputs as well. If not
% specified, these optional inputs will use default values. Check the help
% for the list of optional key/value inputs and their defaults.
help synapseSphere

% These are called key/value inputs because they require both a key and a 
% value, unlike NEURON and SYNAPSE which only required a value. In the info
% that shows up with "help synapseSphere", the keys are the left column
% under "Optional key/value inputs".
% To provide a key/value argument, include the key inside '' (not 
% case-sensitive), then the value:
%   'KEY', value

% So to add synapses to an existing figure, click on it, then use the 'ax'
% key to send gca (which stands for get current axis) to the function.

% Add conventional pre-synapse markers
synapseSphere(c6800, 'ConvPre', 'ax', gca);
% Add the unknown synapses - gray, semi-transparent
synapseSphere(c6800, 'Unknown', 'ax', gca,... 
    'FaceColor', [0.5 0.5 0.5], 'FaceAlpha', 0.5);
% The synapses are created as spheres with a 0.5 micron radius by default. 
% Use the 'MarkerSize'
synapseSphere(c6800, 'ConvPost', 'ax', gca,... 
    'FaceColor', [0 0.3 0.8], 'SF', 0.5);
synapseSphere(c6800, 'RibbonPost', 'ax', gca,... 
    'FaceColor', [0 0.8 0.3], 'SF', 2);

% The synapses are marked by tags following this formula:
%   c + NeuronID + SynapseName
% So RibbonPost synapses on c6800 are all tagged 'c6800RibbonPost'.
% Conventional post-synapses on c121 are all tagged 'c121ConvPost', etc.
%
% This is helpful for editing all the synapses at once using the FINDALL
% command, which "finds all" the objects in the figure matching a certain
% parameter (in this case, matching a specific tag).
%   findall(gcf, 'PropertyName', value);
%
% The SET command takes an object (here you provide a group of objects
% returned by findall), a property ('FaceColor') and the value ([0 1 1]):
%   set(object, 'PropertyName', value);

% Change the FaceColor of post ribbon synapse
set(findall(gcf, 'Tag', 'c6800RibbonPost'), 'FaceColor', [0 1 1]);
% Make them transparent
set(findall(gcf, 'Tag', 'c6800RibbonPost'), 'FaceAlpha', 0.3);

% The synapse size can't be changed afterwards (yet), so to fix the odd
% ribbon synapses, use the DELETE command:
delete(findall(gcf, 'Tag', 'c6800RibbonPost'));
% Then add them again at a more reasonable size...
synapseSphere(c6800, 'RibbonPost', 'ax', gca, 'FaceColor', [0 0.8 0.3]);
