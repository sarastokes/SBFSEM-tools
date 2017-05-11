function StructureColors = getStructureColors()
  % editable StructureColors 
  %
  % 6May2017 - SSP - created


  StructureColors = containers.Map;
  StructureColors('unknown') = [0.5 0.5 0.5];
  StructureColors('gap junction') = rgb('yellow');
  StructureColors('bipolar conventional') = [0 1 1];
  StructureColors('ribbon synapse') = rgb('greenish');
  StructureColors('postsynapse') = rgb('electric blue');
  StructureColors('terminal') = rgb('pink');
  StructureColors('conventional') = rgb('light red');
