function data = updateRegistration(source, zxy, overwrite)
% UPDATEREGISTRATION  Include new xyRegistration in master list
%
% Syntax:
%   data = updateRegistration('i', zxy);
%
% Inputs:
%   source          volume name or abbreviation
%   zxy             Nx3 matrix output from xyRegistration.m
%   overwrite       (false) append to existing or overwrite
%
% Outputs:
%   data            Nx3 matrix written to file
%
% Notes:
%   Split from xyRegistration to add a manual checking step. Currently not
%   setup for NeitzTemporalMonkey or MarcRC1. There are some major issues
%   with this - no check system for double assigning offsets. This is a
%   minimally viable version for a few quick publication figures. Will need
%   to be improved for widespread use.
%
%
% Example:
%{
    data = xyRegistration('i', [1283 1305]);
    % If transform looks legit, send to updateRegistration
    updateRegistration('i', newdata);
%}
%
% History:
%   17Dec2017 - SSP
%   02Jun2021 - SSP - Made more generalized for other volumes
% -------------------------------------------------------------------------

    % source = validateSource(source);
    source = sbfsem.builtin.Volumes.fromChar(source);
    
    if nargin < 3
        disp('Setting overwrite to false');
        overwrite = false;
    else 
        assert(islogical(overwrite), 'overwrite is t/f');
    end

    xyDir = fileparts(mfilename('fullpath'));
    if overwrite % Create a new dataset
        try
            N = source.nSections();
        catch
            error('SBFSEM:updateRegistration', 'Volume does not have nSections');
        end
        % NOTE: 0th section is ignored here
        data = zeros(N, 3); 
        data(:,1) = 1:N;
    else % Load existing file
        try
            data = dlmread([xyDir, filesep, 'XY_OFFSET_', upper(char(source)), '.txt']);
        catch
            error('SBFSEM:updateRegistration',...
                'Unable to load xy offset data file');
        end
    end

    % List of sections with new data
    zList = zxy(:, 1);
    
    % Add to the existing values for new Z sections
    data(zList, 2) = data(zList, 2) + zxy(:, 2);
    data(zList, 3) = data(zList, 3) + zxy(:, 3);   
    
    % Update all sections vitread (less than) the last new Z section
    [minZ, ind] = min(zxy(:, 1));
    data(1:(minZ-1), 2) = data(1:(minZ-1), 2) + zxy(ind, 2);
    data(1:(minZ-1), 3) = data(1:(minZ-1), 3) + zxy(ind, 3); 
    
    dlmwrite([xyDir, filesep, 'XY_OFFSET_', upper(char(source)),'.txt'], data);
    assignin('base', 'xyOffsetData', data);
    
    % Keep track of changes to registration data
    fid = fopen([xyDir, filesep, 'DATA_LOG'], 'a');
    fprintf(fid, '%s\n', datestr(now));
    if overwrite
        fprintf(fid, '--------OVERWRITE--------\n');
    end
    fprintf(fid, 'Updated XY_OFFSET_%s based on sections %u-%u\n\n',...
        upper(char(source)), min(zList), max(zList));
    fclose(fid);
    