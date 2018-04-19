# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox developed for serial EM data and connectomics in the Neitz Lab at University of Washington. While SBFSEM-tools was built around the Viking annotation software, many aspects are quite general and may apply easily to other programs and imaging methods.

SBFSEM-tools provides Matlab support for accessing th connectome annotation database API. Annotation data through Viking's OData service and parsed into Matlab data types. This is abstracted so users can work with familiar objects (neuron, synapse, etc). SBFSEM-tools provides a framework to support data mining and user-defined analysis as well as user interfaces to avoid programming entirely. 

Key features:
- Efficent, accurate 3D rendering of neurons:
  - Volume rendering of Closed Curve annotations
  - Polygon meshes from Disc annotations
  - Segmentation and volume rendering of free-form traces over a stack of EM images. 
- Standard analysis routines for both single neurons and networks.
- Image registration: surfaces from IPL boundary markers, XY offset calculations.
- Support for generating high resolution, publication quality images
- Export 3D models to use in programs like Blender

See the documentation for more information. 

Work in progress: (1) A more intuitive representation of connectivity networks. (2) A more generalized framework for OData queries (in the meantime, contact us if you would like a [Postman][postman] collection explaining common queries). (3) SWC export and support for biophysical models.

##### More information:
* [Viking][viking] annotation software
* [Neitz lab][neitz] at University of Washington
* Contact sarap44@uw.edu

![c6](https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c6_render.png?raw=true)
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true" width="400">

   [neitz]: <http://www.neitzvision.com/>
   [viking]: <https://connectomes.utah.edu/>
   [postman]: <https://www.getpostman.com/>
