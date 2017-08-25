classdef PrimaryDendriteDiameter < NeuronAnalysis
  % PRIMARYDENDRITEDIAMETER
  % See analyzeDS.m for information on use
  %
  % 25Aug2017 - SSP - created

  properties
    keyName = 'PrimaryDendriteDiameter'
  end

  methods
    function obj = PrimaryDendriteDiameter(neuron, varargin)
      validateattributes(neuron, {'Neuron'}, {});
      obj@NeuronAnalysis(neuron);

      obj.doAnalysis(varargin);
    end % constructor

    function doAnalysis(obj, varargin)
      obj.data = analyzeDS(obj.target, varargin);
    end % doAnalysis

  end % methods
  end % classdef
