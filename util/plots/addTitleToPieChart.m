function addTitleToPieChart(axHandle, titlestr, varargin)
    % ADDTITLETOPIECHART
    %
    % Description:
    %   Fixes issue where title overlaps with pie chart labels.
    %
    % Syntax:
    %   addTitleToPieChart(axHandle, titlestr, varargin)
    %
    % Inputs:
    %   axHandle        Handle to axis with pie chart
    %   titlestr        Text for title
    %   varargin        Anything else you would normally pass to title()
    %
    % History:
    %   16Apr2020 - SSP - pulled from plotLinkedNeurons.m in SBFSEM-Tools
    % --------------------------------------------------------------------

    h = title(axHandle, titlestr, varargin{:});
    axHandle.Position(2) = axHandle.Position(2) - 0.05;
    h.Position(2) = h.Position(2) + 0.1;
