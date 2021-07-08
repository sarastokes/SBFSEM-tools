function IDs = renderWhos(figureHandle)
    % RENDERWHOS
    % 
    % Syntax:
    %   IDs = renderWhos(figureHandle);
    %
    % Description:
    %   Returns all the renders in a figure (based on tags)
    %
    % Input:
    %   figureHandle        MATLAB figure (default = gcf)
    %
    % See also:
    %   WHOS
    %
    % History:
    %   14Apr2019 - SSP
    %   27May2021 - SSP - Added gcf as default input
    % ---------------------------------------------------------------------
    
    if nargin < 1
        figureHandle = gcf;
    end
    
    IDs = [];

    h = findall(figureHandle, 'Type', 'patch');

    for i = 1:numel(h)
        hTag = h(i).Tag;
        if ~isempty(hTag)
            hTag(isletter(hTag)) = [];
            IDs = cat(1, IDs, str2double(hTag));
        end
    end

    IDs = sort(IDs, 'ascend');
