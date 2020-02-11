function h = findByTag(parentHandle, tag)
    % FINDBYTAG
    %
    % Description:
    %   Convenience function for finding plot objects by tag
    %
    % Syntax:
    %   h = findByTag(parentHandle, tag)
    %
    % Input:
    %   parentHandle        handle to figure or axes
    %   tag                 char
    %
    % Ouptut:
    %   h                   handle to graphics objects with the tag
    %
    % History:
    %   4Feb2020 - SSP
    % ---------------------------------------------------------------------
    
    h = findall(parentHandle, 'Tag', tag);