# SBFSEM-tools

Synapse analysis and graphing utilities for Scanning Block Face Serial EM.

### Installation

Add each folder's location to your [Matlab path][addpath] along with SBSFEM-tools like so:
```matlab
addpath(genpath('C:\...\SBFSEM-tools'));
```
You will also need to download and install the [GUI Layout Toolbox][guitoolbox]. A second toolbox ([JSONLab][json]) is already included with SBFSEM-tools.

### Basics

1. Export a neuron from Viking and open in [Tulip][tulip].
2. Open Tulip's Python console (bottom toolbar) and define ```outputFile``` to set the filename and save location. For consistency with subsequent naming conventions (Matlab doesn't like variables beginning with numbers), I am naming these after the cell number with 'c' in front (c207.json, c6800.json, etc).

```python
outputFile = "C:\...SBFSEM-data\Temporal\c207.json"
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

```
cellName.openUI;
```
6. After editing the Cell Info panel of the UI, make sure to press the Add Cell Info button. To save a compact version of the neuron, don't use the command line, instead use (File --> Save Cell) from the UI menu bar. 

7. To include a network, repeat the above steps to get the JSON file. Add to an existing cell from the command line, or the UI Connectivity Panel. The program now supports networks with >1 degrees of separation.
```matlab
cellName.addConnectivity('h207.json');
```

8. If you would then like to get far, far away from Matlab, you can export a .csv or .txt file from the Export option on the UI menu bar. To export the connectivity tables use the Export menu item.

A more detailed tutorial/documentation is in progress...

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
