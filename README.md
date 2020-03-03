# SBFSEM-tools

SBFSEM-tools is a Matlab toolbox for connectomics and serial electron microscopy developed by [Sara Patterson][mysite] in the [Neitz Lab][neitz] at University of Washington.  The goal of SBFSEM-tools is a single user-friendly, open source program providing the missing 3D visualization and analysis tools for cylinder-based annotations. Integration with contour/skeleton-based annotations and common morphology file formats is also supported.

#### About
SBFSEM-tools provides Matlab API for analysis and visualization of connectomics annotations. Annotation data is imported through database queries or read from standard file formats, then parsed into Matlab data types. This process is abstracted so users can work with familiar objects like neurons, synapses, etc. SBFSEM-tools provides an object oriented framework to support data mining and user-defined analyses. The key functions can also be accessed without programming through user interfaces. 

Importantly, this program is designed around an interest in open sourcing the data and code used in scientific research. See the [wiki][docs] for information on resources to enable sharing the data and code used by this program for publications.

#### Requirements:
The code in this repository is being developed in Matlab 2018b, but will run with 2015b or higher. A standalone compiled version of the user interface that does not require Matlab is available by request (sarap44@uw.edu). 

#### Key features:
- Object-oriented framework and code base for connectomics datasets
- Efficent, accurate, publication-quality 3D renders of neurons:
  - Polygon meshes from Disc (cylinder) annotations without fitting or smoothing data
  - Volume rendering of Closed Curve (contour) annotations
  - Segmentation and volume rendering of free-form traces over a stack of EM images.
- Standard analysis routines for both single neurons and networks.
- Image registration: generate surfaces for inner retina boundaries, XY offset calculations for quick alignment fixes.
- Import and export models in common neuroscience and 3D printing file formats (SWC, COLLADA, STL)

See the [wiki documentation][docs] for more details.

#### References:
If you use SBFSEM-Tools in your research, please cite:
Patterson et al (2019) [An S-cone circuit for edge detection in the primate retina.][patterson2019] *Scientific Reports*, 9, 11913

A full list of publications using SBFSEM-tools:
- Bordt et al (2019) [Synaptic inputs from identified bipolar and amacrine cells to a sparsely branched ganglion cell in rabbit retina.][bordt2019] *Visual Neuroscience*, 36, E006
- Patterson et al (2019) [An S-cone circuit for edge detection in the primate retina.][patterson2019] *Scientific Reports*, 9, 11913
- Patterson, Bordt et al (2019) [Wide-field amacrine cell inputs to ON parasol ganglion cells in macaque retina.][pattersonbordt2019] *Journal of Comparative Neurology*
- Patterson et al (2020) [A color vision circuit for non-image-forming vision in the primate retina.][patterson2020] *Current Biology*, 30, 1-6

#### More information:
* [Documentation][docs]
* [Viking][viking] annotation software
* [Neitz lab][neitz] at University of Washington
* Request an invite to the [Slack workspace][slack] for tips and questions
* Contact sarap44@uw.edu

<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c6_render.png?raw=true" width=400>
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/flatrender.png?raw=true" width="400">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/colorbystrata.png?raw=true" width="800">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/renderapp_hcs2.png?raw=true" width="400">
<img src="https://github.com/sarastokes/SBFSEM-tools/blob/master/docs/c1441_graphapp.png?raw=true" width="400">

[neitz]: <http://www.neitzvision.com/>
[viking]: <https://connectomes.utah.edu/>
[postman]: <https://www.getpostman.com/>
[docs]: <https://github.com/sarastokes/sbfsem-tools/wiki>
[slack]: <https://retinaconnectome.slack.com>
[patterson2019]: <https://www.nature.com/articles/s41598-019-48042-2>
[bordt2019]: <https://www.cambridge.org/core/journals/visual-neuroscience/article/synaptic-inputs-from-identified-bipolar-and-amacrine-cells-to-a-sparsely-branched-ganglion-cell-in-rabbit-retina/E12F6CFA003864B36E6A12375847B8CE>
[pattersonbordt2019]: <https://onlinelibrary.wiley.com/doi/10.1002/cne.24840>
[patterson2020]: <https://www.cell.com/current-biology/fulltext/S0960-9822(20)30084-1>
[mysite]: <https://sarastokes.github.io>