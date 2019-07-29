function [linkingNodes, startingNodes, terminalNodes] = getSegmentStart(segments)
    % GETSEGMENTSTART
    %
    % Syntax:
    %   [linkingNodes, startingNodes, terminalNodes] =
    %   getSegmentStart(segments);
    %
    % Input:
    %   segments        cell array of segments from dendriteSegmentation
    %
    % Output:
    %   linkingNodes    ID of linking node    
    %   startingNodes   ID of first unique node in each segment
    %   terminalNodes   ID of last node in segment
    %
    % History:
    %   30May2018 - SSP
    % ---------------------------------------------------------------------
    
    linkingNodes = cellfun(@(x) x(end), segments);
    startingNodes = cellfun(@(x) x(end-1), segments);
    terminalNodes = cellfun(@(x) x(1), segments);