# Changelog

### 6Sept2018
- Fixed bug in returning OffEdge and Terminal nodes from `NeuronAPI.m`.
- Edited the main `Tutorial.m` and the wiki.

### 5Sept2018
- Improved `views/ImageStackApp.m` to output cropped images.
- Wrote `tutorial_DendriteDiameter.m` and finished edits to `sbfsem.analysis.DendriteDiameter.m`
- Added external function for creating shaded error bars (`lib/shadedErrorBar.m`).

### 4Sept2018
- Implemented change to `NeuronAPI.m` parent class. All validation of class in `Neuron` functions should now check for a `NeuronAPI` object instead.

### 28Aug2018
- Working version of `sbfsem.io.JSON.m` without metadata exports.
- Added in working `NeuronAPI.m` parent class and two subclasses, `Neuron.m` which imports from OData and `NeuronJSON.m` which imports from existing .json files. The goal is for the different `NeuronAPI` subclasses to be used interchangeably.
- Removed printed file name from `util/registration/omitSections.m`.

### 2Aug2018
- Renamed `PrimaryDendriteDiameter.m` to `DendriteDiameter.m` and made function more user friendly.

### 31Jul2018
- Implemented `util/registration/omitSections.m` and moved code setting the `omittedIDs` property of `Neuron` objects to the `Neuron.pull()` method, to keep omitted IDs in sync with updates.
- Fixed bug in `Neuron.getSynapseNodes()`
- Added option to show nodes labeled Terminal in `GraphApp.m`.
- General bug fixes to `RenderApp.m` and `GraphApp.m`, both are fully functional.

### 23Jul2018
- Updated `util/plots/vissoma.m` to match new method of `Neuron.m`.
- Major updates to `GraphApp.m` and `RenderApp.m`.
- Changed `Neuron.m` parsing of XYZ data to be robust to annotations with and without the SliceToVolume1 transform. For now, synapse locations are ballpark, using `util/import/estimateSynapseXY.m`.
- Added two colormaps missing from `lib/` folder: `lbmap.m` and `viridis.m`.

### 19Jul2018
- `Neuron` class now has a property specifying the XY transform applied to annotation data (`sbfsem.core.Transforms.m`). Default is `SBFSEMTools`, the local transforms found in the `registration/` folder. The `Viking` transform applies the SliceToVolume1 transform. Raw XY values can be used by applying the `None` transform.
- See `RenderApp2.m` for beta updates to `RenderApp.m`
- Also, some small improvements to `GraphApp.m`

### 11Jul2018
- Added `registration/omitSections.m` function for section 915 in NeitzInferiorMonkey.

### 9Jul2018
- Improved `GraphApp.m` with a help panel and an annotation table panel

### 8Jul2018
- Quick revert for soma assignment in `sbfsem.io.SWC.m`.
- Added `views/ConnectivityView.m` to quickly visualize neuron graph connectivity.
- New helper function `util/nearestNodes.m` identifies neuron node closest to an associated synapse marker.

### 30Jun2018
- Corrected error assigning soma in `sbfsem.io.SWC.m`.
- Updates to `sbfsem.ConeMosaic.m`.
- Fixed a bug in `exportSceneDAE.m`.
- Moved Segment class to `sbfsem.render.Segment.m`.

### 9Jun2018
- Improvements to `sbfsem.io.SWC.m` which now ensures ParentID's are always higher than Node IDs.
- Wrote a new class (`sbfsem.analysis.Segments.m`) to handle increasing workload for `dendriteSegmentation.m` function.

### 5Jun2018
- Added `volumeScale` property to `+sbfsem/Ultrastructure.m`.
- Improvements to mitochondria class (`+sbfsem/Mitochondria.m`): updated OData import, added geometries import, function for finding mitochondrial volume.
- New helper function for identifying location IDs of most vitread and sclerad annotations in a single structure (`util/minmaxNodes.m`).

### 4Jun2018
- Rewrote structure link code (`util/import/getLinkedNeurons.m`) but left the old function for backwards compatibility.
- Short tutorial for querying linked structures (`tutorials/tutorial_LinkedNeurons.m`).
- Added a new pair of sections to xy offset translation matrix for NeitzInferiorMonkey (see `data/NeitzInferiorMonkeyRegistration.m`)
- Included RC1-specific post-bipolar cell synapse tags to `+sbfsem/+core/StructureTypes.m`.

### 3Jun2018
- Improved structure link code (`util/import/getStructureLinks.m`) with new JSON decoder compatibility and a new output argument (`synapseIDs`) to link presynaptic neuron IDs to the post-synaptic synapse ID. Still limited: one synapse at a time, no bidirectional synapses.

### 1Jun2018
- Rewrote SWC export algorithm (`+sbfsem/+io/SWC.m`).
- Added a test for graph methods (`test/GraphTest.m`).

### 16May2018
- Minimally working SWC export (`+sbfsem/+io/SWC.m`).

### 27Apr2018
- Debugged `branchRegistration.m` and added several sections to NeitzInferiorMonkey's xy offset file.
- Expanded `hideAxes.m` to take figure inputs, apply to multiple axes in one figure and to show hidden axes.

### 24Apr2018
- Fixed bug caused by single child structure having an empty Tags field (`+sbfsem/+io/SynapseOData.m`)
- More progress on cylinder render tutorial (`cylinderRender.mlx`)

### 23Apr2018
- Added FaceAlpha argument to render functions, temporarily. New Material code will eventually replace this (`sbfsem.render.Material.m`).
- Fixed an RC1 import bug caused by tags without quotes
- Added preliminary cache support (`util/CacheNeuron`);

### 20Apr2018
- Added to `data/OMITTED_IDS_RC1.txt`: 2 locations for c476, 1 for c5542.

### 19Apr2018
- Made `sbfsem.image.VikingFrame` user-friendly and wrote a tutorial, `tutorial_ImageScaleBar.m`

### 18Apr2018
- Cleaned up the `util/analysis` folder and checked `Tutorial.m`
- Data export through `sbfsem.io.JSON` works, volume metadata is still undefined.

### 15Apr2018
- Fixed issue in `parseClosedCurve.m` where str2double was returning a NaN for the first X point of each curve.
- Improved the existing explanations and figures on `cylinderRender.mlx` tutorial. Added better comments to `sbfsem.render.Cylinder.m`.
- Pulled helper functions from `sbfsem.render.Cylinder.m` and added them to the `util` folder: `normalCircle.m`, `getAB.m` and `minimizeRot.m`.

### 14Apr2018
- Work on a JSON export/import option for storing Neurons. This will be used to preserve the state of the neuron/database when data was analyzed for a paper (`sbfsem.io.JSON`).

### 12Apr2018
- Created COLLADA class to organize .dae export code for better testing and consistent ui (`sbfsem.io.COLLADA`).

### 10Apr2018
- New closed curve render function. Works standalone but hasn't been incorporated into closed curve objects yet.
- Fixed error in Neuron\getDAspect()
- Shadow function contains.m for older Matlab versions was causing problems, renamed to `mycontains.m`
- Option to specify the number of spline points for `catmullRomSpline.m` as 100 points was excessive for ClosedCurve renders
- Option to resize volume before rendering (`volumeRender.m`)

### 4Apr2018
- Quick Network method to get number of contacts between a Neuron and other post-synaptic neurons.
- More testing
- Function to parse datetime offset from OData (`parseDatetime.m`)
- gitignore for .asv files

### 2Apr2018
- BoundaryMarker test and small debugging
- Added basic synapses to `tests/NeuronTest.m`
- Fixed GABAPost LocalName assignment error

### 1Apr2018
- Long overdue testing framework
- Fixed bug in Neuron/getSomaID

### 29Mar2018
- Fixed compatibility issues with BoundaryMarker classes

### 26Mar2018
- Support for network queries, final Network structures are still under development.
- Removed need for blank omitted id files for each volume. Now just create one if needed, using data/OMITTED_IDS_RC1.txt as an example.
- Option to switch between SD and SEM in `printStat.m`
- Fixed bug opening help menu in Render App

### 20Mar2018
- Added imagesc option to image stack family (ImageStackApp, ImageNode). Trigger this by specifying a minMax to ImageStackApp or ImageNode.show. The minMax sets the color limits (CLim) of the resulting imagesc plot.

### 17Mar2018
- Updating renders in RenderView no longer resets camera angle.

### 7Mar2018
- New class to coordinate scale bar dimensions of exported Viking frames (`+sbfsem/+image/VikingFrame.m`)

### 6Mar2018
- Added a simple metric for estimating a neuron's IE ratio (`util/analysis/ieRatio.m`)
- Switched JSON decoding to JSONLab, updated all OData classes

### 4Mar2018
- UI improvements: interactive mouse mode for 3d pan/zoom, back to Matlab's default color picker menu, which has really improved in the latest version.
- Moved some infrequently used functions out of Neuron.m and into utility folder: `util/analysis/addAnalysis.m`, `util/renders/getBoundingBox.m`

### 1Mar2018
- Added Viking synapse markers used in RC1 to `+sbfsem/+core/StructureTypes.m`

### 28Feb2018
- Updates to `synapseSphere.m` and a tutorial on how to add synapses to renders (in new tutorial folder - `tutorialSynapseRender.m`).
- Fixed Matlab version compatibility issues with `segmentColorROI.m`

### 25Feb2018
- Beginnings of a Network OData class.. currently just a function for 1 degree networks (getStructureLinks.m)
- Added 3 true/false functions to sbfsem.core.StructureTypes: isPre, isPost and isSynapse
- Fixed issue where synapse LocalName was inside a cell. No more `vertcat(obj.synapses.LocalName{:}` !
- Updated Neuron/synapseIDs method to return synapse IDs (parent ID not location IDs).

### 20Feb2018
- New `numBins` input parameter to decide histogram bins for `IPLDepth.m`
- Added missing helper function (`sem.m`)

### 19Feb2018
- Reorganized folders, cleaned out old code and unused libraries.

### 16Feb2018
- Ability to omit nodes from renders by adding them to `OMITTED_NODES_VOLNAME.txt` in the data folder. The first entry is the cell ID, the second is the location ID. The nodes are omitted when a graph/digraph is made of the neuron's annotations and connections.
- Added updateAll() and getAll() methods to `+sbfsem/ConeMosaic`

### 15Feb2018
- Option to fix axes at XY, YZ and XZ in RenderApp (Plot Modifers -> Set Axis Rotation)
- Updates to the scale bar, now right click on scalebar to limit axes.

### 12Feb2018
- Option for cone outlines of unidentified cone type (label 'uTRACE')
- Fixed bug in `+sbfsem/+render/Cylinder.m`
- Added ScaleBar3 class for 3D scale bars
- ScaleBar and Add Lighting option for RenderApp
- Expanded RenderApp help menus

### 7Feb2018
- Improved boundary renderings - can now be added and removed to scenes
- IPL depth estimates for individual cells (`iplDepth.m`). This is a first pass - it looks good but there's significant room for improvement.
- Matlab figures can be converted to `sbfsem.ui.FigureView` thru constructor
- Fixed issue where images exported from RenderApp all had white backgrounds.

### 6Feb2018
- Added a sbfsem.core.BoundaryMarker subclass for IPL-GCL markers (`sbfsem.core.GCLMarker.m`).
- Semi-transparent overlays with standard RGB values (255/0/0, 0/255/0, 0/0/255) now have defaults in `segmentColorROI.m`

### 28Jan2018
- More efficient version of `clipMesh.m` - deletes unused vertices now
- Fixed some bugs with the Collada export function used outside RenderApp (exportDAE.m)

### 25Jan2018
- New alignment function: branchRegistration. See `data/NeitzInferiorMonkeyRegistration.m` for more details
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
- Preliminary methods for rendering synapses (`synapseSphere.m`) and cone outlines (ConeMosaic.m)

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
