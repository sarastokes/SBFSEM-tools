function StructureColors = getStructureColors()
  % editable StructureColors 
  %
  % 6May2017 - SSP - created


  StructureColors = containers.Map;
  StructureColors('unknown') = [0.5 0.5 0.5];
  StructureColors('gap junction') = rgb('pastel blue'); 
  StructureColors('bip conv pre') = rgb('electric blue');
  StructureColors('bip conv post') = rgb('aquamarine');
  StructureColors('ribbon pre') = rgb('green');
  StructureColors('ribbon post') = rgb('greenish');
  StructureColors('conv pre') = rgb('light red');
  StructureColors('conv post') = rgb('light orange');
  StructureColors('touch') = rgb('aqua');
  
  StructureColors('triad basal') = rgb('light red');
  StructureColors('nontriad basal') = rgb('dark red');
  StructureColors('marginal basal') = rgb('dark red');

  StructureColors('hc bc pre') = rgb('bright lavender');
  StructureColors('hc bc post') = rgb('bright lavender');
  StructureColors('gaba fwd') = rgb('bright lavender');
  
  StructureColors('adherens') = rgb('azure');
  StructureColors('desmosome') = rgb('azure');
  StructureColors('desmosome post') = rgb('azure');
  StructureColors('desmosome pre') = rgb('azure');

  StructureColors('terminal') = rgb('pink');
  StructureColors('off edge') = rgb('peach');
  StructureColors('conventional') = rgb('light red');

  % RC1
  StructureColors('endocytosis') = rgb('light blue');
  StructureColors('postsynapse') = rgb('light orange');
  StructureColors('conventional') = rgb('light red');