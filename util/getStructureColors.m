function StructureColors = getStructureColors()
  % editable StructureColors 
  %
  % 6May2017 - SSP - created


  StructureColors = containers.Map;
  StructureColors('unknown') = [0.5 0.5 0.5];
  StructureColors('gap junction') = rgb('yellow');
  StructureColors('bip conv pre') = rgb('electric blue');
  StructureColors('bip conv post') = rgb('aquamarine');
  StructureColors('ribbon pre') = rgb('green');
  StructureColors('ribbon post') = rgb('greenish');
  StructureColors('conv pre') = rgb('light red');
  StructureColors('conv post') = rgb('orange');
  StructureColors('hc bc pre') = rgb('salmon');
  StructureColors('hc bc post') = rgb('salmon');

  StructureColors('terminal') = rgb('pink');
  StructureColors('off edge') = rgb('peach');
