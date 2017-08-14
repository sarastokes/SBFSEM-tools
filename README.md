# SBFSEM-tools

Synapse and network analyses for serial electron  microscopy. 

SBFSEM-tools uses the Neuron class to represent each cell individually. The Mosaic class supports analysis of groups of Neurons. 
Work in progress: (1) A more intuitive representation of connectivity networks. (2) The model utilities will allow multi-level simulation of cells from Viking. Currently supports only spectral responses to full-field stimuli - explanding to include temporal, then spatial responses.

### Basics
Before you get started, make sure to add SBFSEM-tools to your [Matlab path][addpath] like so:
```matlab
addpath(genpath('C:\...\sbfsem-tools));
```
Here's the basic workflow. If you're comfortable with Python, see the docs for more efficient export options. 
1. Export a neuron from Viking and open in [Tulip][tulip].
2. Open Tulip's Python console (bottom toolbar) and define ```outputFile``` to set the filename and path.

```python
outputFile = "C:\...SBFSEM-data\NeitzTemporal\c207.json"
```
3. Next, type in these two lines to export the cell data

```python
params = tlp.getDefaultPluginParameters('JSON Export', graph)
success = tlp.exportGraph('JSON Export', graph, outputFile, params)
```
4. In Matlab, load and parse the JSON file.
```matlab
cellName = Neuron('c207.json');
```
5. Open the analysis UI
```matlab
NeuronApp(cellName);
```
6. If you would then like to get far, far away from Matlab, you can export a .csv or .txt file from the Export option on the UI menu bar. To export the connectivity tables use the Export menu item.
7. To update the data of an existing Neuron:
```matlab
cellName.updateData('c207.json');
```
8. To include a network, repeat the above steps to get the JSON file. Add to an existing cell from the command line, or the UI Connectivity Panel. The program now supports networks with >1 degrees of separation.
```matlab
cellName.addConnectivity('h207.json');
```
See the documentation for more details. 

##### More information:
* [Viking][viking] SBFSEM annotation software
* Helpful open-source programs: [Tulip][tulip], [Blender][blend]
* Open-source Matlab toolboxes included: [JSONlab][json], [GUI Layout Toolbox][guitoolbox]
* [Neitz lab][neitz] at University of Washington
* Contact sarap44@uw.edu


   [blend]: <http://www.blender.com>
   [neitz]: <http://www.neitzvision.com/>
   [viking]: <https://connectomes.utah.edu/>
   [guitoolbox]: <https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox>
   [json]: <https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files>
   [tulip]: <http://chip.de/downloads/Tulip-64-Bit_41528289.html>
   [addpath]: <https://www.mathworks.com/help/matlab/ref/addpath.html>
