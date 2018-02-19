function StructureColors = getStructureColors()
  % editable StructureColors 
  %
  % 6May2017 - SSP - created
  % 5Sept2017 - SSP - removed RGB calls to speed up


  StructureColors = containers.Map;
  StructureColors('unknown') = [0.5 0.5 0.5];
  StructureColors('gap junction') = [0.584313725490196 0.815686274509804 0.988235294117647]; 
  StructureColors('bip conv pre') = [0.0235294117647059 0.32156862745098 1];
  StructureColors('bip conv post') = [0.0156862745098039 0.847058823529412 0.698039215686274];
  StructureColors('ribbon pre') = [0.0823529411764706 0.690196078431373 0.101960784313725];
  StructureColors('ribbon post') = [0.250980392156863 0.63921568627451 0.407843137254902];
  StructureColors('conv pre') = [1 0.27843137254902 0.298039215686275];
  StructureColors('conv post') = [0.992156862745098 0.666666666666667 0.282352941176471];
  StructureColors('touch') = [0.0745098039215686 0.917647058823529 0.788235294117647];
  
  StructureColors('triad basal') =[1 0.27843137254902 0.298039215686275];
  StructureColors('nontriad basal') = [0.517647058823529 0 0];
  StructureColors('marginal basal') = [0.517647058823529 0 0];

  StructureColors('hc bc pre') = [0.780392156862745 0.376470588235294 1];
  StructureColors('hc bc post') = [0.780392156862745 0.376470588235294 1];
  StructureColors('gaba fwd') = [0.780392156862745 0.376470588235294 1];
  
  StructureColors('adherens') = [0.0235294117647059 0.603921568627451 0.952941176470588];
  StructureColors('desmosome') = [0.0235294117647059 0.603921568627451 0.952941176470588];
  StructureColors('desmosome post') = [0.0235294117647059 0.603921568627451 0.952941176470588];
  StructureColors('desmosome pre') = [0.0235294117647059 0.603921568627451 0.952941176470588];

  StructureColors('terminal') = [1 0.505882352941176 0.752941176470588];
  StructureColors('off edge') = [1 0.690196078431373 0.486274509803922];

  % RC1
  StructureColors('endocytosis') = [0.564705882352941 0.894117647058824 0.756862745098039];
  StructureColors('postsynapse') = [0.992156862745098 0.666666666666667 0.282352941176471];
  StructureColors('conventional') = [1 0.27843137254902 0.298039215686275];