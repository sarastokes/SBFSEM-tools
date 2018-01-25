# Changelog

### 1Jan2018
- Closed curves are now rendered with Catmull-Rom splines (rather than just the control points).
- Improved the default lighting on render figures.

### 3Jan2018
- RenderApp
- Synapses no longer automatically download (huge speed improvement). To import synapses, the 3rd argument of Neuron should be set to true:
```
% Import with synapses
c6800 = Neuron(6800, 'i', true);

% No synapses imported
c6800 = Neuron(6800, 'i');
% Add synapses
c6800.getSynapses();
'''
- A faster way to interact with renders
```
% Before: created a separate render object
c121 = Neuron(121, 't');
r121 = sbfsem.render.Cylinder(c121);
% Now access through the cell
c121.build(); % BUILD creates the model
c121.render(); % RENDER shows the model
% Cylinder is the default, for closed curve:
c2542 = Neuron(2542, 'i');
c2542.build('closed curve');
'''
- I moved Neuron out of the sbfsem folder so no more sbfsem.Neuron or importing sbfsem. Just use Neuron.

### 5Jan2018
- Fixed bugs, added dependencies
- Preliminary methods for rendering synapses (synapseSphere.m) and cone outlines (ConeMosaic.m)

### 11Jan2018
- Dev version of RenderApp 2.0 (working additions: update, remove, cone mosaic. not working: synapses, Z registration, legends)
- Function for limiting render to dendrites (clipMesh.m)
- Synapses are in the docs now, the everything else post-5Jan2018 is not

### 19Jan2018
- Huge update to RenderApp
- Preliminary working version of GraphApp (Tulip replacement)
- Fixed an issue with NeuronOData where update() wasn't actually updating nodes/edges

### 25Jan2018
- New alignment function: branchRegistration. See data/NeitzInferiorMonkeyRegistration.m for more details
- Fixed issue with closed curve render XYZ scaling