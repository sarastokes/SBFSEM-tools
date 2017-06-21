# SBFSEM-tools

Synapse analysis and graphing utilities for Scanning Block Face Serial EM.

### Installation
You will need two free Matlab toolboxes: the [GUI Layout Toolbox][guitoolbox] and [JSONlab][json]. Add each folder's location to your [Matlab path][addpath] along with SBSFEM-tools like so:
```matlab
addpath(genpath('C:\...\SBSFEM-tools'));
```
### Basics

1. Export a neuron from Viking and open in [Tulip][tulip].
2. Open Tulip's Python console (bottom toolbar) and set ```OutputFile``` to set the filename and save location. For consistency with subsequent naming conventions (Matlab doesn't like variables beginning with numbers), I am naming these after the cell number with 'c' in front (c207.json, c6800.json, etc).

```python
OutputFile = "C:\...SBFSEM-data\tulipExports\c207.json"
```

3. Paste in these two lines to export the cell data

```python
params = tlp.getDefaultPluginParameters('JSON Export', graph)
success = tlp.exportGraph('JSON Export', graph, OutputFile, params)
```

4. In Matlab, load and parse the JSON file.

```matlab
cellName = NeuronNodes(loadjson('filename.json'));
```

5. Open the analysis GUI

```
cellName.openGUI;
```
6. After editing the Cell Info panel of the GUI, save the neuron:
```matlab
cellName.saveNeuron;
```
7. To include a connectivity map, repeat the above steps and add to the existing cell. The degrees of separation does not matter - only direct contacts will be imported.
```matlab
cellName.addContacts(loadjson('filename.json'));
```

8. If you would then like to get far, far away from Matlab, you can export a .csv file from the command line or the GUI menu bar (File --> Export).
```matlab
cellName.exportCell('csv');
```

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
