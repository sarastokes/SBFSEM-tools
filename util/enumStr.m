function x = enumStr(enum)
    % ENUMSTR  
    %
    % Description:
    %   Returns only the 2nd output of Matlab's enumeration fcn
    %
    % Syntax:
    %   x = enumStr(enum)
    %
    % Input:
    %   enum        Name of enumeration class as a char
    %
    % Output:
    %   x           Cell array of enumeration member names [Nx3]
    % 
    % History:
    %   29Oct2017 - SSP
    %   31Jan2020 - SSP - Moved from ephys package, added documentation
    % ---------------------------------------------------------------------

    [~, x] = enumeration(enum);