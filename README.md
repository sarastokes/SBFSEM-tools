# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox developed for serial EM data and connectomics in the Neitz Lab at University of Washington. While SBFSEM-tools was built around the Viking annotation software, many aspects are quite general and may apply easily to other programs and imaging methods.

SBFSEM-tools imports annotation data through Viking's OData service and parses the results into Matlab data types. This happens behind the scenes so users can work with familiar objects (neuron, synapse, etc). Other features include:
- Single neuron analysis: dendritic field area, dendrite diameter, soma size, stratification, synapse distribution
- Group analysis: density recovery profile, nearest neighbor, synapse statistics
- Efficent 3D rendering of neurons, support for generating high-resolution, publication-quality images:
  - Volume rendering of Closed Curve annotations
  - Polygon meshes from Disc annotations
  - Segmentation and volume rendering of free-form traces over a stack of EM images. 
  - Support for generating high resolution, publication quality images
  - Export 3D models to use in programs like Blender
- Image registration: surfaces from IPL boundary markers, XY offset calculations.
- Misc UIs for visualizing renders, EM images and annotations

See the tutorials and documentation for the most up to date information. 

Work in progress: (1) A more intuitive representation of connectivity networks. (2) A more generalized framework for OData queries (in the meantime, contact me for a [Postman][postman] collection with common queries). (3) SWC export and support for biophysical models.

##### More information:
* [Viking][viking] annotation software
* [Neitz lab][neitz] at University of Washington
* Contact sarap44@uw.edu

![c6](https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c6_render.png?raw=true)
![renderapp](https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true)
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true" width="400">

   [neitz]: <http://www.neitzvision.com/>
   [viking]: <https://connectomes.utah.edu/>
   [postman]: <https://www.getpostman.com/>