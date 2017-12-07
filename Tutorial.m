% SBFSEM-tools tutorial
% The purpose of this tutorial is to demonstrate the program's basic
% capabilities while checking to ensure each component is installed
% correctly. I'm hoping this will be clear even to those who haven't worked
% with Matlab before.

%% First add sbfsem-tools to your path by editing the filepath below:
addpath(genpath('C:\users\...\sbfsem-tools'));

%% Toolbox check
% Check community toolboxes to make sure GUI Layout Toolbox is installed
struct2table(matlab.addons.toolbox.installedToolboxes)

% Check for JSONLab in sbfsem-tools.
if isempty(which('loadjson.m'))
	% as long as sbfsem-tools and subfolders are on your path, this
	% shouldn't occur
	error('Add entire sbfsem-tools package to your path');
else
	% You may have other versions of loadjson.m installed. These might
	% throw errors so if this doesn't return the version in sbfsem-tools,
	% remove the other path
	if isempty(strfind('sbfsem-tools', which('loadjson.m')))
		fprintf('Removing %s from path\n', which('loadjson.m'));
		rmpath(which('loadjson.m'));
	end
end

%% Import from OData

% Create a Neuron object Neuron(cellID, 'source');
c6800 = sbfsem.Neuron(6800, 'temporal');
% Note: sources are 'temporal', 'inferior', 'rc1' but will
% recognize any abbreviation like 't', 'inf', etc
c2975 = sbfsem.Neuron(2795, 'i');

% I replaced NeuronApp with individual plots:
% 3D node plot
fh = sbfsem.ui.NodeView(c6800);
% Stratification and synapses along the z-axis
fh = sbfsem.ui.StratificationView(c6800);
% Histogram of proximal-distal synapse density:
fh = sbfsem.ui.SomaDistanceView(c6800);

% Note: most of the data structures used by sbfsem tools are objects. To
% get an idea of what an object like "sbfsem.Neuron" contains, type it into
% the command line:
c2795
% This will return a list of the "properties" which are basically the
% different types of data stored in the object. You could also use
properties(c2795) % or
properties(sbfsem.Neuron)

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
%% Rendering
% Import an L/M-cone annotated with closed curves
c2542 = sbfsem.Neuron(2542, 'i');
% Render!
lmcone = sbfsem.render.ClosedCurveRender(c2542, 0.3);
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
% geometries. The ClosedCurveRender function will create them
% if they aren't present. However, if you want to access that
% data without rendering, use this:
c2542.setGeometries();
% The data is stored under the "geometries" property
geometryData = c2542.geometries;

% -------------------------------------------------------------------------
%% ImageStack class
% In Viking: Export frames from viking to a dedicated folder

% ImageStack represents the images as a doubly linked list
% Creating ImageStack imports all .png files in that folder, 
% relying on the numbering system created by Viking's export frames
imStack = ImageStack(folderPath);
% Open in image stack app
ImageStackApp(imStack);
% You can use the right and left arrow keys to move through

% Create a GIF
[im, map] = stack2gif(ImageStack);
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