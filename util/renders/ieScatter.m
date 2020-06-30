function ax = ieScatter(neuron, varargin)
    % IEPLOT
    %
    % Syntax:
    %   ax = iePlot(neuron, 'showUnknown', false, 'FaceAlpha', 0.65)
    %
    % Inputs:
    %   neuron          Neuron object
    % Optional key/value inputs:
    %   ax              Axes handle (default = new figure axes)
    %   showUnknown     Show unknown synapses (default = false)
    %   faceAlpha       Marker transparency (default = 0.65)
    %
    % See also:
    %   iePlot
    %
    % History:
    %   19Jun2020 - SSP
    %   29Jun2020 - SSP - Added support for varargin to scatter plot
    % ---------------------------------------------------------------------
    
    ip = inputParser();
    ip.CaseSensitive = false;
    ip.KeepUnmatched = true;
    addParameter(ip, 'ax', [], @ishandle);
    addParameter(ip, 'FaceAlpha', 0.65, @isnumeric);
    addParameter(ip, 'ShowUnknown', false, @islogical);
    parse(ip, varargin{:});
    showUnknown = ip.Results.ShowUnknown;
    faceAlpha = ip.Results.FaceAlpha;
    ax = ip.Results.ax;
    
    neuron.checkSynapses();
    if isempty(ax)
        ax = golgi(neuron);
    else
        golgi(neuron, 'ax', ax);
    end
    
    inh_xyz = neuron.getSynapseXYZ('ConvPost');
    exc_xyz = neuron.getSynapseXYZ('RibbonPost');
    out_xyz = neuron.getSynapseXYZ('ConvPre');
    
    if ~isempty(inh_xyz)
        mark3D(inh_xyz, 'ax', ax, 'Color', rgb('peach'),... 
            'FaceAlpha', faceAlpha, 'Scatter', true);
    end
    if ~isempty(exc_xyz)
        mark3D(exc_xyz, 'ax', ax, 'Color', hex2rgb('00cc4d'),...
            'FaceAlpha', faceAlpha, 'Scatter', true);
    end
    if ~isempty(out_xyz)
        mark3D(out_xyz, 'ax', ax, 'Color', hex2rgb('ff4040'),...
            'FaceAlpha', faceAlpha, 'Scatter', true);
    end
    
    if showUnknown
        idk_xyz = neuron.getSynapseXYZ('Unknown');
        if ~isempty(idk_xyz)
            mark3D(idk_xyz, 'ax', ax, 'Color', rgb('gray'),...
                'FaceAlpha', faceAlpha, 'Scatter', true);
        end
    end
    
    h = findall(ax, 'Type', 'scatter');
    arrayfun(@(x) set(x, 'ZData', ax.ZLim(2) + zeros(size(x.ZData))), h,...
        'UniformOutput', false);
    set(h, 'SizeData', 60);
    set(h, ip.Unmatched);