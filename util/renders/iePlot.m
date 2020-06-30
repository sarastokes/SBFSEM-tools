function ax = iePlot(neuron, varargin)
    % IEPLOT
    %
    % Description:
    %   Renders 2D projection of neuron along with ConvPre, ConvPost and
    %   RibbonPost synapses marked in red, orange and green, respectively
    %
    % Syntax:
    %   ax = iePlot(neuron, varargin)
    %   
    % Input:
    %   neuron          Neuron object
    %   Optional additional key/value inputs are passed to mark3D to
    %   control the appearance of the synapse markers
    %
    % See also:
    %   MARK3D
    %
    % History:
    %   15May2020 - SSP
    %   29Jun2020 - SSP - Direct golgi render to specified axis
    % ---------------------------------------------------------------------
    
    neuron.checkSynapses();
    
    ip = inputParser();
    ip.KeepUnmatched = true;
    ip.CaseSensitive = false;
    addParameter(ip, 'ax', [], @ishandle);
    parse(ip, varargin{:});
    ax = ip.Results.ax;
    
    if isempty(ax)
        ax = golgi(neuron);
    else
        golgi(neuron, 'ax', ax);
    end
    
    inh_xyz = neuron.getSynapseXYZ('ConvPost');
    exc_xyz = neuron.getSynapseXYZ('RibbonPost');
    out_xyz = neuron.getSynapseXYZ('ConvPre');
    
    if ~isempty(inh_xyz)
        h1 = mark3D(inh_xyz, 'ax', ax,... 
            'Color', rgb('peach'), 'Tag', 'inh', ip.Unmatched);
    end
    if ~isempty(exc_xyz)
        h2 = mark3D(exc_xyz, 'ax', ax,...
            'Color', hex2rgb('00cc4d'), 'Tag', 'exc', ip.Unmatched);
    end
    if ~isempty(out_xyz)
        h3 = mark3D(out_xyz, 'ax', ax,...
            'Color', hex2rgb('ff4040'), 'Tag', 'out', ip.Unmatched);
    end
    