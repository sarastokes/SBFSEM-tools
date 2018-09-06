# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox developed for serial EM data and connectomics in the [Neitz Lab][neitz] at University of Washington. While SBFSEM-tools was built around the Viking annotation software, many aspects are quite general and may apply easily to other programs and imaging methods.

#### About
SBFSEM-tools provides Matlab support for accessing the connectome annotation database API. Annotation data is queried through Viking's OData service and parsed into Matlab data types. This is abstracted so users can work with familiar objects like neuron, synapse, etc. SBFSEM-tools provides a framework to support data mining and user-defined analysis. However, the key functionality can be accessed without programming through user interfaces.

Importantly, this program is designed around an interest in open sourcing the data and code used in scientific research. See the wiki for information on resources to enable sharing the data and code used in by this program for publications.

#### Key features:
- Efficent, accurate 3D rendering of neurons:
  - Volume rendering of Closed Curve annotations
  - Polygon meshes from Disc annotations
  - Segmentation and volume rendering of free-form traces over a stack of EM images.
- Standard analysis routines for both single neurons and networks.
- Image registration: surfaces from IPL boundary markers, XY offset calculations.
- Support for generating high resolution, publication quality images
- Export 3D models to use in programs like Blender, ParaView and NEURON

See the [wiki documentation][docs] for more details.

#### Work in progress:
- A more intuitive representation of connectivity networks.
- A more generalized framework for OData queries (in the meantime, contact us if you would like a [Postman][postman] collection explaining common queries).

#### More information:
* [Documentation][docs]
* [Viking][viking] annotation software
* [Neitz lab][neitz] at University of Washington
* Contact sarap44@uw.edu

![c6](https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c6_render.png?raw=true)
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true" width="400">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c1441_graphapp.png?raw=true" width="400">

[neitz]: <http://www.neitzvision.com/>
[viking]: <https://connectomes.utah.edu/>
[postman]: <https://www.getpostman.com/>
[docs]: <https://github.com/sarastokes/sbfsem-tools/wiki>
