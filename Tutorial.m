% SBFSEM-tools tutorial
% The purpose of this tutorial is to demonstrate the program's basic
% capabilities while checking to ensure each component is installed
% correctly. I'm hoping this will be clear even to those who haven't worked
% with Matlab before.

%% First add sbfsem-tools to your path by editing the filepath below:
addpath(genpath('C:\users\...\sbfsem-tools'));
% There's also a "Set path" button on MATLAB's top toolbar, in the
% "Environment" panel. Make sure to click the button that lets you add all
% subfolders too.

%% Import the SBFSEM toolbox 
% Otherwise you will have to type 'sbfsem.Neuron' instead of 'Neuron'
import sbfsem.*;

%% Import from OData
% Create a Neuron object Neuron(cellID, 'source');
c6800 = Neuron(6800, 'temporal');
% Note: sources are 'temporal', 'inferior', 'rc1' but will
% recognize any abbreviation like 't', 'inf', etc
c2975 = Neuron(2795, 'i');

% Note: most of the data structures used by sbfsem tools are objects. To
% get an idea of what an object like "sbfsem.Neuron" contains, type it into
% the command line:
c2795
% This will return a list of the "properties" which are basically the
% different types of data stored in the object. You could also use
properties(c2795) % or
properties('sbfsem.Neuron')

%% Closed Curve Renders
% Import an L/M-cone annotated with closed curves
c2542 = Neuron(2542, 'i');
% Render!
lmcone = renderClosedCurve(c2542, 'sampling', 0.8);
% The 2nd argument is scale factor. The scale factor changes the image 
% sizes used in rendering. This has two effects:
% First, lower scale factors reduce the computation time.
% Second, the scale factor changes the final product. If the render looks 
% too grainy and just looks like a stack of closed curve annotations, try 
% reducing the scale factor to <1. If the render lacks detail, set the 
% scale factor >1.

% The render in the figure is a property of the output. Here are some 
% helpful ways to manipulate this:
% Change the color
set(lmcone.renderObj, 'FaceColor', [0.2 0.5 0.9]);
% Make the render transparent
set(lmcone.renderObj, 'FaceAlpha', 0.5);
% Enable 3D rotating (or use the button on the figure toolbar)
rotate3d;

% Note: the initial import doesn't create the closed curve 
% geometries. The render function will create them
% if they aren't present. However, if you want to access that
% data without rendering, use this:
c2542.setGeometries();
% The data is stored under the "geometries" property
geometryData = c2542.geometries;

%% Disc renders
% Import a parasol RGC (note: the larger cells can take awhile to import)
c5 = Neuron(5, 't');
c121 = Neuron(121, 't');
% Create Cylinder render objects
r5 = sbfsem.render.Cylinder(c5);
r121 = sbfsem.render.Cylinder(c121);
% Render - this will create a new figure
r5.render();

% If you want to add more neurons to this figure, you'll need a way of
% telling Matlab where to send the new neurons. The easiest way to do this
% is to make sure the figure is your "active" window (the active window is
% whichever you last clicked on). The "gca" command (get current axis) will
% then tell Matlab to send the new neuron to the axis the existing one is
% plotted on. 
% While you're at it, you might want to change the neuron's color. This can 
% be done by ('facecolor', [r g b]).
r121.render('ax', gca, 'facecolor', [0 0.8 0.3]);

% Add a light at the current rotate position (you can do this multiple
% times)
camlight;
% Occasionally if you're on rotate mode, you'll have to go back to the
% pointer for this to take effect

% Make the figure look nicer
axis tight; axis off;

% If you want a black background
set(gcf, 'Color', 'k'); % gcf = get current figure
axis on; % Axis must be on to change attributes
set(gca, 'Color', 'k');
% If you don't want the axis showing
set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');

% OR you can select the "Show plot tools" button on the toolbar (it's the
% last button to the right). This gives a UI to edit plot attributes.


%% Views
% I replaced NeuronApp with individual plots:
% 3D node plot
NodeView(c6800); % The rotate3d part is broken right now.. will fix soon!
% Stratification and synapses along the z-axis
StratificationView(c6800);
% Histogram of proximal-distal synapse density:
SomaDistanceView(c6800);

% -------------------------------------------------------------------------
%% Data tables
% The bulk of a Neuron's data is stored in it's dataTable. I chose this 
% data structure as it's similar to Excel - a program everyone in the 
% collaboration is comfortable with.

% Here are a few examples of queries..
% Count the number of each synapse type
[G, synapseNames] = findgroups(c207.dataTable.LocalName);
N = splitapply(@numel, c207.dataTable.LocalName, G);
N % returns the number per synapse
synapseNames % returns the names of those synapses

% Get all the Location IDs for unique ribbon synapses
rows = strcmp(c207.dataTable.LocalName, 'ribbon pre');
% Here's a new table with only the rows matching your query
T = c207.dataTable(rows,:);
T.Location % returns the location IDs!
% More information can be found in matlab's documentation for the table
% class. Typing
doc table
% should get you to the right area.
% -------------------------------------------------------------------------
%% IPL Boundary surface
% Create a surface from INL-IPL or INL-GCL boundary markers
inl = sbfsem.core.INLBoundary('i');

% To update the boundary marker locations from OData
inl.refresh();

% Create a surface from the marker locations
inl.doAnalysis();

% Plot the surface:
plot(inl);
% To see the surface without the raw data
plot(inl, false);

% You can alsow increase the surface resolution (default=100 points)
inl.doAnalysis(500);


% -------------------------------------------------------------------------
%% XY alignment
% Get statistics on the XY offset of a stack of sections
% Queries all neurons in a range of Z sections and finds mean, median XY
% offset (in pixels, relative to the most sclerad section).
S = xyRegistration('i', [1283 1304], true);

% -------------------------------------------------------------------------
%% ImageStack class
% In Viking: Export frames from viking to a dedicated folder

% ImageStack represents the images as a doubly linked list
% Creating ImageStack imports all .png files in that folder, 
% relying on the numbering system created by Viking's export frames
imStack = sbfsem.image.ImageStack(folderPath);
% Open in image stack app
ImageStackApp(imStack);
% You can use the right and left arrow keys to move through

% Create a GIF
[im, map] = stack2gif(imStack);
imwrite(im, map, 'foldername/filename.gif',... 
	'DelayUpdate', 0,...
	'Loop', inf);

%% ------------------------------------------------------------
%% NeuronAnalysis class
% This class will make population data on common analyses easier to manage
% and reproduce by organizing input parameters and results.

% load in an h1 horizontal cell
load c28

% Here's the primary dendrite diameter analysis:
a = PrimaryDendriteDiameter(c28);
% add it to the neuron:
c28.addAnalysis(a);
% Each analysis has input parameters that may vary
a = PrimaryDendriteDiameter(c28, 'searchBins', [3 6]);
% These parameters are saved to the neuron with the analysis object
c28.addAnalysis(a);
% To overwrite an existing analysis, set overwrite priviledges to true
c28.addAnalysis(a, true);

% Here's an 2nd example with the dendritic field convex hull analysis:

% This cell has an axon that shouldn't be included in dendritic field area.
axonCheck(c28);
% Remove the axon with the data brush option (toolbar) next click on the
% cell body. This makes the cell the currently active object (might need to
% first select the mouse button on the toolbar)
xy = xyFromPlot(gco);
% xy is the new, axonless matrix of annotation locations

% Get the dendritic field hull and return a plot. The object returned
% stores your xy values so you won't have to remove the axon again later.
foo = DendriticFieldHull(c28, xy);

% Add this to the neuron
c28.addAnalysis(foo);
% If you already have a DendriticFieldHull