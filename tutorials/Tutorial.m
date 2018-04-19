% SBFSEM-tools tutorial
% The purpose of this tutorial is to demonstrate the program's basic
% capabilities while checking to ensure each component is installed
% correctly. I'm hoping this will be clear even to those who haven't worked
% with Matlab before.

%% First, add sbfsem-tools to your path by editing the filepath below:
addpath(genpath('C:\users\...\sbfsem-tools'));
% There's also a "Set path" button on MATLAB's top toolbar, in the
% "Environment" panel. Make sure to click the button that lets you add all
% subfolders too.

% -------------------------------------------------------------------------
%% RenderApp
% -------------------------------------------------------------------------
% The RenderApp is a VikingPlot substitute that requires minimal use of the
% command line. To get started type:
RenderApp();
% Hover over each button for instructions. Click on the graph and press the
% 'h' key for instructions on navigation. If the navigation keys aren't 
% working, make sure you click on the graph first. See the documentation 
% for more details.

% -------------------------------------------------------------------------
%% Neurons
% -------------------------------------------------------------------------
% Create a Neuron object:
% 	X = Neuron(ID, 'source');
c6800 = Neuron(6800, 'temporal');
% Note: sources are 'temporal', 'inferior', 'rc1' but will
% recognize any abbreviation like 't', 'inf', etc
c2975 = Neuron(2795, 'i');

% By default, Neurons are imported without synapses.
% Include them by setting the 3rd argument to true (default = false)
c2795 = Neuron(2795, 'i', true);
% Or add to an existing structure
c6800.getSynapses();

% Print the synapses
c6800.printSyn();
% This returns both the Viking synapse names and more detailed synapse
% names used by sbfsem-tools.

% If you're actively annotating a cell and want to update it, use:
c2795.update();

% -------------------------------------------------------------------------
%% Views
% -------------------------------------------------------------------------
% I replaced NeuronApp with individual plots:
% 3D node plot
NodeView(c6800);
% Stratification and synapses along the z-axis
StratificationView(c6800);
% Histogram of proximal-distal synapse density:
SomaDistanceView(c6800);

% -------------------------------------------------------------------------
%% Volumetric renders for Closed Curve annotations
% -------------------------------------------------------------------------
% Import an L/M-cone annotated with closed curves
c2542 = Neuron(2542, 'i');
% Render!
c2542.build('closedcurve', 'sampling', 0.8);
% The 2nd argument is scale factor. The scale factor changes the image 
% sizes used in rendering. This has two effects:
%   1.) lower scale factors reduce the computation time.
%   2.) the scale factor changes the final product. If the render looks 
% too grainy and just looks like a stack of closed curve annotations, try 
% reducing the scale factor to <1. If the render lacks detail, set the 
% scale factor >1. 
% The default sampling = 1.

% Note: The build and render functions are not separate like cylinder
% renders (yet...). So you have to rebuild the model each time you render.

% Use exportSceneDAE for closed curve renders
c2542.render('FaceColor', [0, 0.4, 1]);
exportSceneDAE(gca, 'lmcone.dae');

% -------------------------------------------------------------------------
%% Polygon mesh renders for Disc annotations
% -------------------------------------------------------------------------
% Build a 3D model of an existing neuron:
c6800.build('cylinder');
% Note: 'cylinder' is the default render value so this works too
r6800 = c6800.build();
% You can either specify an output for the render (ex: r6800) or access it
% as a property of the neuron
r6800
c6800.model

% Render the 3D model
c6800.render();

% Add a 2nd neuron to the render:
c121 = Neuron(121, 't');
c121.build();
% If you want to add more neurons to this figure, you'll need a way of
% telling Matlab where to send the new neurons. The easiest way to do this
% is to make sure the figure is your "active" window (the active window is
% whichever you last clicked on). The "gca" command (get current axis) will
% then tell Matlab to send the new neuron to the axis the existing one is
% plotted on. 
c121.render('ax', gca, 'facecolor', [0 0.8 0.3]);
% Change the neuron's color with ('facecolor', [rgb]). 
% Node RGB values in matlab are between 0-1, not 0-255. If you want to 
% convert, use:         [R G B]/255
% I also included a hex2rgb function:   rgb = hex2rgb('#000000');

% To edit the figures: select the "Show plot tools" button on the toolbar 
% (last button to the right). This opens a UI to edit plot attributes.

% Some other helpful commands:
view(3);    % An easy way to switch to 3D view
grid on;    % XYZ grid


% Smooth the render by increasing the smooth function iterations:
c121.model.setSmoothIter(2);
% The default is 1 and in most cases, additional iterations are detrimental
c121.render();
% Smoothing is applied at render time so it's easy to change:
c121.model.setSmoothIter(1);

% I'm currently working on more sophisticated mesh smoothing techniques and
% hope to have them available soon.

% -------------------------------------------------------------------------
%% Single section closed curve outlines
% -------------------------------------------------------------------------
% For structures like cone pedicles, single closed curve annotations can be
% added to a render with the 'outline' option

% Import an L/M-cone:
c5751 = Neuron(5751, 'i');
% Import a neighboring S-cone:
c5752 = Neuron(5752, 'i');
% Build the renders:
c5751.build('outline');
c5752.build('outline');
% Plot both to the same figure
c5751.render('EdgeColor', 'k');
c5752.render('ax', gca,...
    'FaceColor', [0, 0.4, 1],...
    'FaceAlpha', 0.1,...
    'EdgeColor', [0, 0.4, 1]);
% -------------------------------------------------------------------------
%% COLLADA export
% -------------------------------------------------------------------------
% Note for COLLADA export code:
% If you get an error about the Java heap, go to Preferences -> General ->
% Java Heap Memory, and increase it. This will also make figure resizing
% faster!

% To export a single neuron to a COLLADA file for Blender use:
c121.dae();

% To export a scene, pass the axis handle and a file name. 
exportSceneDAE(gca, 'DemoScene.dae');
% You can reduce the number of faces in the final product by specifying the
% percent of faces to retain. This reduces the file size and often has
% little effect on the final product. Recommended = 0.8-1
exportSceneDAE(gca, 'DemoScene2.dae', 0.9);
% For both methods, a dialog box will prompt you to select the folder.

% To learn more about the face reduction, see Matlab's function
doc reducepatch
% To visualize the effects of reducepatch, set the render
c121.model.setReduction(0.6);
c121.render('reduce', true);

% See the documentation for how to import and improve renders in Blender.

% -------------------------------------------------------------------------
%% IPL Boundary surface
% -------------------------------------------------------------------------
% Create a surface from INL-IPL or INL-GCL boundary markers
inl = sbfsem.builtin.INLBoundary('i');

% To update the boundary marker locations from OData
inl.update();

% Create a surface from the marker locations
inl.doAnalysis();

% Plot the surface:
plot(inl);
% To see the surface with the raw data
plot(inl, 'showData', true);

% You can alsow increase the surface resolution (default=100 points)
inl.doAnalysis(500);

% -------------------------------------------------------------------------
%% XY alignment
% -------------------------------------------------------------------------
% Get statistics on the XY offset of a stack of sections
% Queries all neurons in a range of Z sections and finds mean, median XY
% offset (in pixels, relative to the most sclerad section).
S = xyRegistration('i', [1283 1304], true);

% -------------------------------------------------------------------------
%% NeuronGroup class
% -------------------------------------------------------------------------
% A basic NeuronGroup class allows you to hold multiple neurons in a single
% data structure and perform several group-related methods.

% Create NeuronGroups by providing a list of IDs or Neuron objects
h1hc = sbfsem.NeuronGroup([28, 447, 619], 'i');

% Add a neuron
h1hc.add(4568);
% Remove a neuron
h1hc.remove(4568);

% A more detailed description of these methods is in the documentation.

% Get soma size statistics
somaSizes = h1hc.somaDiameter();
% Plot the somas
h1hc.somaPlot('addLabel', true);

% -------------------------------------------------------------------------
%% NeuronAnalysis class
% -------------------------------------------------------------------------
% This class will make population data on common analyses easier to manage
% and reproduce by organizing input parameters and results.

% Note: I'm still trying to decide what to do with NeuronAnalysis so this
% is likely to change in the future.

import sbfsem.analysis.*;

% Import two horizontal cells
c4568 = Neuron(4568, 'i');
c28 = Neuron(28, 'i');

% Here's the primary dendrite diameter analysis:
a = PrimaryDendriteDiameter(c28);
a.plot();
% Here's an 2nd example with the dendritic field convex hull analysis:
a = DendriticFieldHull(c4568);
a.plot();

%% Neuron Analysis class part 2
% The 2nd cell has an axon that should be excluded from analysis.
a = DendriticFieldHull(c28);
a.plot();

axonCheck(c28);
% Remove the axon with the data brush option (toolbar) next click on the
% cell body. This makes the cell the currently active object (might need to
% first select the mouse button on the toolbar)
xy = xyFromPlot(gco);
% xy is the new, axonless matrix of annotation locations

% Get the dendritic field hull and return a plot. The object returned
% stores your xy values so you won't have to remove the axon again later.
a = DendriticFieldHull(c28, xy);

% -------------------------------------------------------------------------
%% ImageStack class
% In Viking: Export frames from viking to a dedicated folder
% This part of the tutorial requires you to input a folder name... See the
% Documentation for quicker info on how this all works

% ImageStack represents the images as a doubly linked list
% Creating ImageStack imports all .png files in that folder, 
% relying on the numbering system created by Viking's export frames
folderPath = 'C:\...';

imStack = sbfsem.image.ImageStack(folderPath);
% Open in image stack app
ImageStackApp(imStack);
% You can use the right and left arrow keys to move through

% Create a GIF
[im, map] = stack2gif(imStack);
imwrite(im, map, 'foldername/filename.gif',... 
	'DelayUpdate', 0,...
	'Loop', inf);

% See documentation for info on image segmentation.
