# Changelog

### 4Mar2018
- UI improvements: interactive mouse mode for 3d pan/zoom, back to Matlab's default color picker menu, which has really improved in the latest version.
- Moved some infrequently used functions out of Neuron.m and into utility folder: util/analysis/addAnalysis.m , util/renders/getBoundingBox.m

### 1Mar2018
- Added Viking synapse markers used in RC1 to +sbfsem/+core/StructureTypes.m

### 28Feb2018
- Updates to synapseSphere.m and a tutorial on how to add synapses to renders (in new tutorial folder).
- Fixed Matlab version compatibility issues with segmentColorROI.m

### 25Feb2018
- Beginnings of a Network OData class.. currently just a function for 1 degree networks (getStructureLinks.m)
- Added 3 true/false functions to sbfsem.core.StructureTypes: isPre, isPost and isSynapse
- Fixed issue where synapse LocalName was inside a cell. No more `vertcat(obj.synapses.LocalName{:}` !
- Updated Neuron/synapseIDs method to return synapse IDs (parent ID not location IDs).

### 20Feb2018
- New 'numBins' input parameter to decide histogram bins for IPLDepth.m
- Added missing helper function (sem.m)

### 19Feb2018
- Reorganized folders, cleaned out old code and unused libraries.

### 16Feb2018 
- Ability to omit nodes from renders by adding them to OMITTED_NODES_VOLNAME.txt in the data folder. The first entry is the cell ID, the second is the location ID. The nodes are omitted when a graph/digraph is made of the neuron's annotations and connections.
- Added updateAll() and getAll() methods to sbfsem.ConeMosaic

### 15Feb2018
- Option to fix axes at XY, YZ and XZ in RenderApp (Plot Modifers -> Set Axis Rotation)
- Updates to the scale bar, now right click on scalebar to limit axes.

### 12Feb2018
- Option for cone outlines of unidentified cone type (label 'uTRACE')
- Fixed bug in +sbfsem/+render/Cylinder.m
- Added ScaleBar3 class for 3D scale bars
- ScaleBar and Add Lighting option for RenderApp
- Expanded RenderApp help menus

### 7Feb2018
- Improved boundary renderings - can now be added and removed to scenes
- IPL depth estimates for individual cells (iplDepth.m). This is a first pass - it looks good but there's significant room for improvement.
- Matlab figures can be converted to sbfsem.ui.FigureView thru constructor
- Fixed issue where images exported from RenderApp all had white backgrounds.

### 6Feb2018
- Added a sbfsem.core.BoundaryMarker subclass for IPL-GCL markers (sbfsem.core.GCLMarker).
- Semi-transparent overlays with standard RGB values (255/0/0, 0/255/0, 0/0/255) now have defaults in segmentColorROI.m

### 28Jan2018
- More efficient version of clipMesh.m - deletes unused vertices now
- Fixed some bugs with the Collada export function used outside RenderApp (exportDAE.m)

### 25Jan2018
- New alignment function: branchRegistration. See data/NeitzInferiorMonkeyRegistration.m for more details
- Fixed issue with closed curve render XYZ scaling

### 19Jan2018
- Huge update to RenderApp
- Preliminary working version of GraphApp (Tulip replacement)
- Fixed an issue with NeuronOData where update() wasn't actually updating nodes/edges

### 11Jan2018
- Dev version of RenderApp 2.0 (working additions: update, remove, cone mosaic. not working: synapses, Z registration, legends)
- Function for limiting render to dendrites (clipMesh.m)
- Synapses are in the docs now, the everything else post-5Jan2018 is not

### 5Jan2018
- Fixed bugs, added dependencies
- Preliminary methods for rendering synapses (synapseSphere.m) and cone outlines (ConeMosaic.m)

### 3Jan2018
- RenderApp
- Synapses no longer automatically download (huge speed improvement). To import synapses, the 3rd argument of Neuron should be set to true:
```
% Import with synapses
c6800 = Neuron(6800, 'i', true);

% No synapses imported
c6800 = Neuron(6800, 'i');
% Add synapses
c6800.getSynapses();
'''
- A faster way to interact with renders
```
% Before: created a separate render object
c121 = Neuron(121, 't');
r121 = sbfsem.render.Cylinder(c121);
% Now access through the cell
c121.build(); % BUILD creates the model
c121.render(); % RENDER shows the model
% Cylinder is the default, for closed curve:
c2542 = Neuron(2542, 'i');
c2542.build('closed curve');
'''
- I moved Neuron out of the sbfsem folder so no more sbfsem.Neuron or import.sbfsem. Just use Neuron.


### 1Jan2018
- Closed curves are now rendered with Catmull-Rom splines (rather than just the control points).
- Improved the default lighting on render figures.
