# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox for connectomics and serial electron microscopy developed by Sara Patterson in the [Neitz Lab][neitz] at University of Washington.  The goal of SBFSEM-tools is a single user-friendly, open source program providing the missing 3D visualization and analysis tools for cylinder-based annotations. However, integration with contour/skeleton-based annotations and common morphology file formats is also supported.

#### About
SBFSEM-tools provides Matlab support for accessing the connectome annotation database API. Annotation data is queried through Viking's OData service or imported from standard file formats and parsed into Matlab data types. This is abstracted so users can work with familiar objects like neurons, synapses, etc. SBFSEM-tools provides an object oriented framework to support data mining and user-defined analyses, however, the key functionality can be accessed without programming through user interfaces.

Importantly, this program is designed around an interest in open sourcing the data and code used in scientific research. See the [wiki][docs] for information on resources to enable sharing the data and code used by this program for publications.

#### Key features:
- Efficent, accurate, publication-quality 3D renders of neurons:
  - Polygon meshes from Disc (cylinder) annotations without fitting or smoothing data
  - Volume rendering of Closed Curve (contour) annotations
  - Segmentation and volume rendering of free-form traces over a stack of EM images.
- Standard analysis routines for both single neurons and networks.
- Image registration: generate surfaces for inner retina boundaries, XY offset calculations for quick alignment fixes.
- Export models in common neuroscience and 3D printing file formats (STL, COLLADA, SWC)

See the [wiki documentation][docs] for more details.

#### Requirements:
The code in this repository is being developed in Matlab 2018b, but will run with 2015b or higher. A standalone compiled version of the user interface that does not require Matlab is available by request (sarap44@uw.edu). 

#### References:
If you use SBFSEM-Tools in your research, please cite:
Sara S. Patterson et al; An S-cone circuit for edge detection. bioRxiv. doi: [https://doi.org/10.1101/667204][preprint]

#### More information:
* [Documentation][docs]
* Recent publications: [Patterson et al. biorxiv][preprint], [Bordt et al. (2019) Vis Neurosci][bordt2019]
* [Viking][viking] annotation software
* [Neitz lab][neitz] at University of Washington
* Request an invite to the [Slack workspace][slack] for tips and questions
* Contact sarap44@uw.edu

![c6](https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c6_render.png?raw=true)
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/smidget.png?raw=true" width="300">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true" width="400">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c1441_graphapp.png?raw=true" width="400">

[neitz]: <http://www.neitzvision.com/>
[viking]: <https://connectomes.utah.edu/>
[postman]: <https://www.getpostman.com/>
[docs]: <https://github.com/sarastokes/sbfsem-tools/wiki>
[slack]: <https://retinaconnectome.slack.com>
[preprint]: <https://doi.org/10.1101/667204>
[bordt2019]: <https://www.cambridge.org/core/journals/visual-neuroscience/article/synaptic-inputs-from-identified-bipolar-and-amacrine-cells-to-a-sparsely-branched-ganglion-cell-in-rabbit-retina/E12F6CFA003864B36E6A12375847B8CE>