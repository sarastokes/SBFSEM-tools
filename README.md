# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox developed for serial EM data and connectomics in the Neitz Lab at University of Washington. While SBFSEM-tools was built around the Viking annotation software, many aspects are quite general and may apply easily to other programs and imaging methods.

SBFSEM-tools imports annotation data through Viking's OData service and parses the results into Matlab data types. This happens behind the scenes so the average user can work with familiar objects (neuron, synapse, etc). Other features include:
- Single neuron analysis: dendritic field area, dendrite diameter, soma size, stratification, synapse distribution
- Group analysis: density recovery profile, nearest neighbor, synapse statistics
- 3D volume rendering of circle (Disc) annotations, polygon (ClosedCurve) annotations and free-form traces over a stack of EM images. 
- 2D projections of dendritic fields.
- Image registration: surfaces from IPL boundary markers, XY offset calculations.
- Misc UIs for visualizing EM images and annotations

See the tutorial and documentation for the most up to date information. 

Work in progress: (1) A more intuitive representation of connectivity networks. (2) SWC export. (3) Better framework for supporting Viking-specific OData queries (in the meantime, contact me for a [Postman][postman] collection with common queries). (4) Apply IPL boundary surfaces and XY alignments to XYZ data.

##### More information:
* [Viking][viking] annotation software
* Helpful open-source programs: [Tulip][tulip], [Blender][blend]
* [Neitz lab][neitz] at University of Washington
* Contact sarap44@uw.edu


   [blend]: <http://www.blender.com>
   [neitz]: <http://www.neitzvision.com/>
   [viking]: <https://connectomes.utah.edu/>
   [tulip]: <http://chip.de/downloads/Tulip-64-Bit_41528289.html>
   [pytulip]: <http://tulip.labri.fr/Documentation/4_10_0/tulip-python/html/index.html>
   [addpath]: <https://www.mathworks.com/help/matlab/ref/addpath.html>
   [postman]: <https://www.getpostman.com/>
