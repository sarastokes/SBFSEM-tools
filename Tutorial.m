% SBFSEM-tools tutorial
% 29Sept2017 - several aspects are now out of date with new OData import.
% I will fix this soon.

% The purpose of this tutorial is to demonstrate the program's basic
% capabilities while checking to ensure each component is installed
% correctly. I'm hoping this will be understandable even to those who
% haven't worked with matlab before

%% First add sbfsem-tools to your path by editing the filepath below:
addpath(genpath('C:\users\...\sbfsem-tools'));

%% Toolbox check
% Check community toolboxes to make sure GUI Layout Toolbox is installed
struct2table(matlab.addons.toolbox.installedToolboxes)

% Check for JSONLab in sbfsem-tools.
if isempty(which('loadjson.m'))
	% as long as sbfsem-tools and subfolders are on your path, this
	% shouldn't occur
else
	% You may have other versions of loadjson.m installed. These might
	% throw errors so if this doesn't return the version in sbfsem-tools,
	% remove the other path
	if isempty(strfind('sbfsem-tools', which('loadjson.m')))
		rmpath(which('loadjson.m'));
	end
end

%% Import from OData

% Create a Neuron object Neuron(cellID, 'source');
c207 = Neuron(207, 'temporal');
% Note: sources are 'temporal', 'inferior', 'rc1' but will
% recognize any abbreviation like 't', 'inf', etc

% Open the UI
NeuronApp(c207);

%% ------------------------------------------------------------
% Data table The bulk of a Neuron's data is stored in it's dataTable. 
% I chose this data structure as it's similar to Excel - a
% program everyone in the collaboration is comfortable with.

% Here's a few examples of queries..

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

%% ------------------------------------------------------------
%% ImageStack class
% In Viking: Export frames from viking to a dedicated folder

% ImageStack represents the images as a doubly linked list
% Creating ImageStack imports all .png files in that folder, relying on the numbering system created by Viking's export frames
imStack = ImageStack(folderPath);
% Open in image stack app
ImageStackApp(imStack);

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

%% ------------------------------------------------------------
% 29Sept2017 - Mosaic class is now out of date with new OData system
% Fixing this is on the list
%
% Mosaic class - Everything in the repository is functional, however, the
% underlying code is still changing - current Mosaic objects may not be
% compatible with future updates... Here's a brief intro and I'll add more
% once the code is stable.

% The Mosaic class was originally designed with visualizing and analyzing
% cone mosaics, however, the code works with mosaics of other cell types or
% really any group of cells.

% load the (currently incomplete) cone mosaic from the demo folder
load('coneMosaic.mat');

% Note: If you're already familiar with matlab, Mosaic is really just a
% table. Unfortunately, Matlab doesn't allow subclassing table. If you're
% familiar with matlab tables and want to work with the mosaic as a table:
% T = table(MosaicName);

% I like the table class for visualizing the attributes of a small number
% of components. Tables make this information easily readable from the
% command line:
disp(PR);

%% Working with Mosaics
% Add a neuron to an existing mosaic:
PR.add(c643);

% Update data of a neuron already in the mosaic
PR.update(c643);

% Add works for existing neurons as well and will return a dialog box
% asking if you'd like to overwrite the existing entry
PR.add(c643);

% Remove a neuron - you can accomplish this in two ways: By cell number:
PR.rmNeuron(643);
% By row number:
PR.rmRow(10);

% Add a Neuron from file (as opposed to a Neuron in the workspace) Make
% sbfsem-tools/demo your current directory
cd('../sbfsem-tools/demo');
PR.loadadd('c643.mat');

% Create a figure that visualizes the mosaic. Similar to the Neuron class,
% the largest annotation is assumed to be the "soma" (with photoreceptors,
% this is actually the first section after the processes end). Blue =
% S-cone, Red = LM-cone, Black = rod
PR.somaPlot();


