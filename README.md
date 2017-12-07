# SBFSEM-tools

Tools for working with Viking SBFSEM data in Matlab. 

- Imports annotation data through Viking's OData service and parses the results into Matlab data structures
- Single cell analyses: dendritic field area, dendrite diameter, soma size, stratification, synapse distribution
- Group analysis: density recovery profile, nearest neighbor, synapse statistics
- 3D renders: volume rendering of closed curves and traces over a stack of EM images.
- Generate surfaces from IPL boundary markers.
- Various methods for visualizing EM stacks, structure annotations

See the tutorial or documentation for the most up to date information. 

Work in progress: (1) A more intuitive representation of connectivity networks. (2) SWC export. (3) Better framework for supporting Viking-specific OData queries (in the meantime, contact me for a [Postman][postman] collection with common queries).

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
   [postman]: <https://www.getpostman.com/>
