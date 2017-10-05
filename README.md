# SBFSEM-tools

Synapse and network analyses for serial electron microscopy. 

The program automatically downloads data from the annotation database to ensure analysis reflects the most recent changes. There are 6 main classes:
1. Neuron - holds all synapse and stratification data about a single neuron
2. Mosaic - for comparing a small number of parameters among multiple neurons
3. Network - represents a network of connected neurons as a directed graph
4. Model - simulates responses to light/current stimuli
5. Analysis - standardizes common analyses by organizing input parameters and results
6. ImageStack - represents EM frames as a doubly linked list, basic image editing support

Work in progress: (1) A more intuitive representation of connectivity networks. (2) The model utilities will allow multi-level simulation of cells from Viking. Currently supports only spectral responses to full-field stimuli - explanding to include temporal, then spatial responses.

See the documentation for more details. 
Note: As of 29Sept2017, much of the documentation and tutorial is out of date. This will be fixed soon.

##### More information:
* [Viking][viking] annotation software
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
   [pytulip]: <http://tulip.labri.fr/Documentation/4_10_0/tulip-python/html/index.html>
   [addpath]: <https://www.mathworks.com/help/matlab/ref/addpath.html>
