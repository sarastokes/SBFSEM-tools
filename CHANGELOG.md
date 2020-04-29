# Changelog

### 20200429
- Added option to import neurons from workspace to `views\RenderApp.m`
- Added `lib\uigetvar.m`
- Added log panel to `views\RenderApp.m`

### 20200427
- Added support for pressing `Enter` key to import neurons in `views\RenderApp.m`

### 20200424
- Added `sbfsem.ui.ColorMaps.m` and `sbfsem.builtin.Volumes.m` to `views\RenderApp.m`

### 20200303
- Renamed `sbfsem.core.VikingStructureTypes` to `sbfsem.builtin.StructureTypes`.
- Updated URLs and images in `README.md`.

### 20200218
- Added `util\renders\annotationDotPlot.m`

### 20200213
- Added `util\analyses\singleDendriteStratification.m`
- Consolidated commonly used code for single dendrite analysis:
    - Added `sbfsem.core.StructureAPI\getBranchNodes.m`
    - Added `util\analyses\createStatsStructure.m`

### 20200211
- Added TypeID query and table output to `sbfsem.io.OData\getUserLastStructures.m`

### 20200204
- Added `util\plots\toggleAxes.m`, now `util\plots\hideAxes.m` only hides
- Added `util\renders\mark3D.m` and phasing out `sbfsem.util.plot3.m`
- Added `util\plots\view2D.m` for easy formatting of figures and axes for 2D renders

### 20200203
- Fixed title overlap in `util\import\getContributions.m`
- Changed x-axis labels in `util\analysis\iplDepth.m` plot
- Added single neuron option for DAE file export to `views\RenderApp.m`
- New 2D scalebar (`sbfsem.ui.ScaleBar2.m`), replaced 3D scalebar in `views\RenderApp.m`

### 20200202
- Wrote histogram UI `sbfsem.ui.HistogramView` and implemented for dendrite diameter in `views\RenderApp.m`

### 20200201
- Improved axis limit UI in `views\RenderApp.m`

### 20200131
- Added enumeration to cell array converter: `util\enumStr.m`
- Source list in major functions now calls `sbfsem.builtin.Volumes.m`
- Removed unused code: `util\import\getVikingURL.m`

### 20200121
- Account for secretly directed "undirected" Touch synapses similar to Unknown synapses (`util\network\getLinkedNeurons.m`)

### 20200117
- Added catch for adding a neuron that is already imported in `views\RenderApp.m`
- Updated `util\network\countLinkedNeurons.m` for `Neuron.links` property

### 20200116
- Added catch for older MATLAB versions that don't have `NumColumns` legend property in `util\analysis\iplDepth.m`

### 20200114
- Updated `util\plot\showLinkededSynapses.m` and `util\network\plotLinkedNeurons.m` for `Neuron.links` property
- Added command line output for number of linked synapses out of total to `util\renders\showLinkedNeurons.m`
- Made `links` a public property of `Neuron.m` (so the output can be sorted in variable viewer).

### 20200110
- Fixed troubles handling "undirected" synapses stored with unpredictable directionality in `util\network\getLinkedNeurons.m`
- Added links property and methods to `Neuron.m`.

### 20200109
- Better plotting for `util\analysis\getSynapseStratification.m`
- Added linked neuron label to synapse tables and rearranged output columns for `util\network\getAllLinkedNeurons.m`
- Added query for a structure label to `sbfsem.io.OData.m`

### 20190106
- Material stays constant while updating neurons in `views\RenderApp.m`

### 20190104
- Added option to change render material in `views\RenderApp.m` under the Plot tab.

### 20191209
- Rolling out support for new volume: NeitzNasalMonkey

### 20191205
- Added `util\analysis\getSynapseSomaDistance.m` which is just the calculation part of `views\SomaDistanceView.m`
- Added `util\analysis\getSynapseDirection.m`

### 20191204
- Updated exception handling in `sbfsem.io.SynapseOData` for Viking glitch where deleted synapses retain their StructureID and links but have no actual locations. Also made cmd line output less redundant. 
- Added cell ID labels to `sbfsem.analysis.DendriticFieldHull.m`

### 20191202
- Changed default `EdgeColor` to black in `util\renders\synapseMarker.m`

### 20191118
- Added`util\plots\colorByUser.m`.
- Added `getUsername()` method to `sbfsem.io.OData.m`
- Parent axes handle key/value input to `util\network\neuronGraphPlot.m`.

### 20191115
- Wrote wrapper for Matlab's `plot3` function (`sbfsem.util.plot3`)
- Added `sbfsem.util.` for wrapper and potentially shadowed functions

### 20191112
- New visualization of strata in a single section (`util\plots\stratificationMap`);
- Added stratification map to `views\IPLDepthApp.m`

### 20191111
- Added `getSynapseStratification.m` 
- Reverted SWC export function `sbfsem.io.SWC.m` and updated links accordingly

### 20191106
- Added new colormap, `lib\cubehelix.m`

### 20191104
- Added `util\network\countLinkedNeurons.m`

### 20191001
- Added more error catching to `util\network\getLinkedNeurons.m`
- Improved plotting for `util\analysis\iplDepth.m`

### 20190930
- Added boxes with bold labels to `+sbfsem\+ui\LayoutManager.m`

### 20190929
- Removed `assignin` from `util\network\getLinkedNeurons.m` leftover from debugging

### 26Sep2019
- Added new methods to `sbfsem.core.NeuronAPI` for returning specific subsets of synapses.

### 23Sep2019
- Added mean, median and error to legend of plot in `sbfsem.analysis.DendriteDiameter`.

### 21Sep2019
- Added `lib\progressbar.m` and a wrapper (`sbfsem.ui.ProgressBar.m`) that limits to iterations over 50. Implemented in `sbfsem.io.SynapseOData.m`.
- Debug multiple variable output of `util\network\getLinkedNeurons.m` to be compatible with 10Sep2019 changes.

### 10Sep2019
- Fixed issue where `util\network\getLinkedNeurons.m` throws an error for conventional synapses involving more than one pre- or post-synaptic neuron. These rare cases probably involve an annotation error, but the rest of the analysis should be able to proceed without problems.

### 21Aug2019
- Changed inputs to `util\network\neuronGraphPlot.m` and updated dependencies accordingly
- Preparing to implement `sbfsem.analysis.NeuronGraph.m` by added all useful standalone network functions.

### 10Aug2019
- Added `util\renders\showLinkedSynapses.m`

### 29Jul2019
- All closed curves on a single section are now rendered together (`util\renders\renderClosedCurve.m`).
- Added extra stats to `util\render\iplDepth.m` output
- Added no soma dendrite diameter analysis to `views\RenderApp.m`

### 28Jul2019
- Improvements to function help and several old tutorials

### 20Jul2019
- Lighting stays consistent when updating neurons in `views\RenderApp.m`

### 15Jul2019
- Fixed bug where the `colorSegments` function of `views\GraphApp.m` threw errors for neurons with over 512 segments.

### 26Jun2019
- Offline mode now compatible with `util\viking2micron.m`

### 23Jun2019
- Small UI initialization fixes in `util\views\GraphApp.m`

### 22Jun2019
- Error messages for `util\analysis\singleDendriteDiameter.m` now return location IDs instead of node number

### 19Jun2019 
- Added Copy button to `util\views\GraphApp.m`

### 18Jun2019
- Adding some old UI improvements to `util\views\RenderApp.m` and `util\views\IPLDepthApp.m`
- Documentation within class for `sbfsem.core.BoundaryMarker.m`

### 29May2019
- Added report to cmd line for `util\analysis\singleDendriteDiameter.m`

### 28May2019
- Fixed reporting for `sbfsem.analysis.DendriteDiameter` where the `includeSoma` parameter was not passed to the `report` function.
- Removed an incorrect help line from `tutorials\tutorial_DendriteDiameter.m`
- `util\network\plotPathLength.m` now operates in microns and `util\analysis\helpers\fastEuclid3d.m` take two arrays of Nx3 XYZ locations.
- Updated boundary marker cache files for NeitzInferiorMonkey

### 21May2019
- New render visualization helper function (`util\renders\randomColors.m`) to randomly assign colors to all patch objects in figure

### 19May2019
- New path length from soma graph visualization (`util\network\plotPathLength.m`)
- Updated `util\network\neuronGraphPlot.m` to accomodate increasing incidences of annotations in database without locations

### 18May2019
- Updated boundary marker cache files for NeitzTemporalMonkey
- Added function `data\cacheBoundaryMarkers.m` to automate cache updates

### 14May2019
- Worked on issue with arbitrary directionality assigned to Unknown synapses in database
- Updated `util\network\getAllLinkedNeurons.m`, `util\network\getLinkedNeurons`, `+sbfsem\+core\NeuronAPI.m`

### 5May2019
- Added color argument to `util\renders\golgi.m`

### 16Apr2019
- Added synapse location to `util\network\getLinkedNeurons.m` and edited the output parsing. If there's only a single output, all arguments will be returned as a table.
- Updated functions using `util\network\getLinkedNeurons.m` to be compatible with new output
- New 2D synapse function `util\render\synapseMarker.m`

### 14Apr2019
- Added function for returning renders in a figure (`util\renders\renderWhos.m`)

### 7Apr2019
- Removed `model` from cached data in `sbsfem.io.JSON.m`

### 3Apr2019
- Added IPL stratification colorbar function (`util\plots\addColorbarIPL.m`)
- Improved input parsing for golgi imitation plots (`util\plots\golgi.m`)

### 7Mar2019
- Option to suppress plot in `util\analysis\iplDepth.m`
- New function for calculating diameter of a single dendrite (`util\analysis\singleDendriteDiameter.m`)
- Added `+sbfsem\+exception\NotYetImplemented.m` subclassing MException to imitate Python's NotImplementedError

### 2Mar2019
- Fixed a small volume abbreviation error in `tutorial_Tortuosity.m`

### 1Mar2019
- Changed some colormaps in `views\RenderApp.m` 
- Removed dependence on 2017b from `sbfsem.analysis.DendriticFieldHull.m` by adding in some `geom2d` functions

### 18Feb2019
- Added option for dendritic field centroids and improved plotting to `sbfsem.analysis.DendriticFieldHull.m`
- Dendritic field hull calculation added as an analysis option to `views\RenderApp.m`
- Added mode calculation and margin parameter to `util\analysis\iplDepth.m` and improved plotting

### 10Feb2019
- New function for plotting flatmount renders like Golgi stain images (`util\renders\golgi.m`)
- Added option to input synapse structure IDs to `synapseSphere.m`

### 2Feb2019
- Compiled trial version of standalone RenderApp software, based on repo at this time.

### 24Jan2019
- Fixed bug in `sbfsem.analysis.DendriteDiameter\table` by removing parameter struct from the data to be converted to a table.

### 19Jan2019
- Returned option for exporting high and low resolution images in `views\RenderApp.m`

### 17Jan2019
- Added options for fixed color limits and colorbar for stratification colormaps in `views\RenderApp.m`
- Fixed error in `sbfsem.io.OData\getUserLastStructures.m`
- Removed `isInverted` property from `views\RenderApp.m`
- Fixed background invert bug in `views\RenderApp.m` that prevented switching from black to white

### 10Jan2019
- Added boundary marker cache files for `RC1`

### 7Jan2019
- Fixed export of high resolution `.tiff` files in `RenderApp.m`.

### 2Jan2019
- Fixed error in loading `RenderApp.m` for RC1

### 21Dec2018
- Fixed error in number of annotations in `util\import\getContributions.m` figure title
- Added `sbfsem.io.OData\getUserLastStructures`
- Fixed toggle of blood vesseles in `views\RenderApp.m`

### 16Dec2018
- Added `isMac` option to `views\RenderApp.m` to circumvent rendering errors when running MATALB on parallels
- Added `lib\igamm.m` from the Machine Vision Toolbox for gamma correction of EM images

### 15Dec2018
- Updated INL boundary markers for NeitzInferiorMonkey to omit 50 markers placed with different criteria
- Small improvements to `views\RenderApp.m` including single neuron export menu and better LastModified annotation appearance

### 11Dec2018
- Added `util\network\getAllLinkedNeurons.m` which runs `getLinkedNeurons.m` for each synapse type in a neuron.

### 9Dec2018
- Simplified `views\RenderApp.m` code with neurons containers.Map using tag instead of char(ID) keys

### 8Dec2018
- Added option to `getContributions.m` in `views\RenderApp.m` 
- Improved plotting in `getContributions.m`
- Added `plotLinkedNeurons.m` to make a pie chart of linked neuron synapse count

### 6Dec2018
- Better visualization: `docs\iplboundary.png`
- Fixed duplication of `data\NEITZINFERIORMONKEY_GCL.txt` boundary markers

### 5Dec2018
- Fixed overlap in terminals/offedges and unfinished nodes.

### 3Dec2018
- New base graph plot: `util/network/neuronGraphPlot.m`

### 1Dec2018
- IMPORTANT: `offEdge` is no longer used for unfinished branches, now used for branches running off the edge of volume (as intended). There is now a separate dependent property in `sbfsem.core.StructureAPI.m` called `unfinished` for unfinished branches, which are identified as having a degree of 1.
- Support for new unfinished/off edge distinction in `views\GraphApp.m`.
- Added a unfinished check in `tests\NeuronTest.m`
- Changed default colormap in `views\RenderApp.m` to haxby (`lib\haxby.m`).

### 30Nov2018
- New class for volumes (`+sbfsem\+builtin\Volumes.m`) to be phased into rendering UIs

### 28Nov2018
- Added `util\render\clipStrataCData.m` so now  RenderApp stratification colormaps now clip anything outside-10 to 110% IPL depth to keep colormaps relevant.

### 26Nov2018
- Added resize function for `views\GraphApp.m`.
- Fixed small bug in constant variable `SYNAPSES` in `views\RenderApp.m`. 

### 25Nov2018
- Access volume scale offline with `util\import\loadCachedVolumeScale.m`. Also helpful for `NeuronJSON.m` compatibility with `sbfsem.core.StructureAPI.m`
- Fixed bugs with `NeuronJSON.m`.
- Big improvements to `views\RenderApp.m`: better RC1 support, import and view neuron .json files, window resize fcn

### 20Nov2018
- Improvements to `util\renders\synapseSphere.m`

### 19Nov2018
- Cleaned function for determining user contributions (`util\import\getContributions.m`)
- Added a tutorial for using the contributions function (`tutorials\tutorial_Contributions.m`)

### 18Nov2018
- Show area of last modified annotation in `views\RenderApp.m` using new function `util\import\getLastModifiedAnnotation.m`.
- Added option to input Synapse ID into `sbfsem.core.NeuronAPI\getSynapseXYZ.m`
- Updated version of `util\network\degreePlot.m` with force3 layout for newer MATLAB version

### 16Nov2018
- Added colorblind colormaps to `views\RenderApp.m`: ametrine and isolum
- Replace the rare NaN values returned from `util\renders\getStrataCData.m` with median depth. Not a long-term solution but will keep the code running.

### 15Nov2018
- Comprehensive reciprocal synapse function (`+sbfsem\+io\ReciprocalSynapses.m`) ported from python version

### 13Nov2018
- Fixed a Neuron import issue that was skipping synapse LocalName columns
- Updated documentation for `util\analysis\helpers\fastEuclid3d.m`

### 12Nov2018
- New `SomaStatsView.m` which can be reached through the neuron uimenu in `views\RenderApp.m`.
- Layouts in `sbfsem.ui.LayoutManager.m` now return the handle of the text component and the parent handle.
- Table tab in `views\GraphApp.m` now doesn't populate until selected to cut down on init time on 

### 8Nov2018
- Added STL export for single neurons (`+sbfsem\+io\STL.m`).
- Removed bar plot option from `util\analysis\iplDepth.m`
- Created a default stratification plot (`util\plots\blankStrataPlot.m`).

### 6Nov2018
- Fully debugged IPL stratification colormaps in `RenderApp.m`.

### 5Nov2018
- Added class for laminated bodies (annotated as `sbfsem.core.OrganizedSER.m`)

### 4Nov2018
- Working colormaps by IPL depth in `views\RenderApp.m` but needs debugging

### 3Nov2018
- Function for setting render color data by stratification (`util\renders\getStrataCData`)

### 2Nov2018
- Debugged 915 gap and set transparency for boundary markers in `RenderApp.m`
- Added a nice plot to `IPLDepthApp.m`

### 1Nov2018
- Added `sbfsem.core.Nucleolus` for analysis and rendering of nucleolus child structures.

### 30Oct2018
- Fixed toggling IPL boundaries in `views\RenderApp.m`.
- Made `addToScene` and `deleteFromScene` functions in `sbfsem.core.BoundaryMarker.m` more robust.

### 28Oct2018
- Removed unused library toolbox functions (toolbox-graph and most of matGeom)
- Fixed arrow direction in `util\network\addToNetwork.m` and changed parameter name from `useWeights` to `weighted` in `util\network\plotNetwork.m`
- Added utility functions: `util\plots\lighten.m`, `util\analysis\helpers\printOffEdges.m`.
- Fixed `util\analysis\iplDepth.m` for InferiorMonkey
- More informative error messages in `views\RenderApp.m`

### 18Oct2018
- Fixed issue with `RenderApp.m` UI layout for NeitzTemporalMonkey and MarcRC1
- Added StructureID to synapse data cursor window in `GraphApp.m`
- New class for working with all blood vessels as a group (`sbfsem.builtin.Vasculature`)
- A parent class for groups of structures (`sbfsem.core.StructureGroup.m`)

### 14Oct2018
- Added `util.analysis.surfaceArea.m`
- Added `meshgrid` function to `sbfsem.core.BoundaryMarker.m`

### 9Oct2018
- Updated cached call to IPL boundaries in `IPLDepthApp.m`
- Set `InvertHardcopy` of default rendering figures to `off`

### 8Oct2018
- New approach for caching
- Major `RenderApp.m` improvements (context panel)

### 7Oct2018
- Added `util\network` folder containing queries and functions for created directed graphs representing a neuron network.
- Added static method to `sbfsem.core.StructureTypes` to get StructureTypes objects from string inputs. Meant for quick command line usage and is limited to the most common StructureTypes, for now.
- Created `+deprecated` folder for objects like `NeuronGroup.m`
- Added a `fromCache` method to `sbfsem.builtin.ConeMosaic.m`

### 6Oct2018
- Changed `sbfsem.core.StructureAPI` properties `offedge` and `terminals` to not Transient. This will fix some the issues displaying these properties in `GraphApp.m` after updating a neuron.

### 4Oct2018
- Working version of `IPLDepthApp.m`
- Small changes to import of Boundary Markers and added cached boundaries to `data\`

### 3Oct2018
- Changed Data Cursor output from XYZ to Section number in `GraphApp.m`
- Automatic import of OData for `sbfsem.builtin.GCLBoundary` and `sbfsem.builtin.INLBoundary`. Updated tutorial to include information on how to cache the results of the OData query with `cachedcall.m`.
- Added analysis function and tutorial for parasol paper: `util\analysis\tortuosity.m` and `tutorials\tutorial_Tortuosity.m`.

### 2Oct2018
- New startup dialog for `GraphApp.m` and user interface improvements

### 29Sept2018
- Fixes to `sbfsem.core.BoundaryMarker` and subclasses
- Fixed bugs introduced by `sbfsem.core.StructureAPI.m`
- Added `sbfsem.core.VesselAdjacency.m`

### 26Sept2018
- Major class changes. Added `StructureAPI.m` above `NeuronAPI.m` so StructureTypes that can be treated mostly like Neurons (such as blood vessels) don't have to replicate code.
- New `sbfsem.core.BloodVessel.m` class for Blood Vessel annotations
- Added status bar to `views/GraphApp.m` and improved plotting of updated neurons
- Added public methods to `sbfsem.render.Segment.m` for converting between location IDs in Viking and node IDs in the graph representation.

### 25Sept2018
- Extended `sbfsem.analysis.AnnotationsSizes.m` to include CDF and normalization for plotting.
- Convinience functions for tortuosity analysis: `euclideanDist2.m`, `euclideanDist3.m`, `plotXYZ.m` in utils folder.
- Small optimizations for `GraphApp.m`
- Removed `save` method from `Neuron.m`

### 18Sept2018
- New analysis `sbfsem.analysis.AnnotationSizes.m` for creating histograms of annotation sizes. 
- Removed unused class `sbfsem.core.Transform.m`
- Wrote minimal tutorial on boundary surfaces `tutorial_BoundarySurfaces.m`

### 10Sept2018
- Computer vision tutorial `tutorial_DiscToClosedCurveAI.m`
- Fixed typo in Nucleolus structure tag in `sbfsem.core.StructureTypes.m`

### 9Sept2018
- Important change to default Transform used in NeitzInferiorMonkey. For now on, the default Transform (Viking) will be used. To work with the S-OFF midget dataset, pass `transform='SBFSEM-tools'` to `Neuron.m`. 
- Added input parsing and vitread shift option to `util/registration/branchRegistration.m`. Updated `data/NeitzInferiorMonkeyRegistration.m` to reflect updates in input parsing.

### 7Sept2018
- Updated namespace for `sbfsem.render.Primitives.m`.

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
- Fixed error in `Neuron\getDAspect`
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
