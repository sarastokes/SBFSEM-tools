import swc2vtk
vtkgen = swc2vtk.VtkGenerator()
vtkgen.add_swc('c4568.swc')
vtkgen.write_vtk('c4568.vtk')