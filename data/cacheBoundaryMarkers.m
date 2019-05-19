function cacheBoundaryMarkers(entity, dataDir)
    % CACHEBOUNDARYMARKERS
    %
    % Syntax:
    %   cacheBoundaryMarkers(entity, dataDir)
    %
    % Inputs:
    %   entity              sbfsem.core.BoundaryMarker subclass
    % Optional inputs:
    %   dataDir             File path to save cache, if empty dialog will
    %                       ask user for the file path.
    %
    % Example:
    %   % Create the GCLBoundary object
    %   x = sbfsem.builtin.GCLBoundary('t');
    %   % Query the database for all boundary markers (slow)
    %   x.update();
    %   % Save the cache
    %   cacheBoundaryMarkers(x);
    %
    % See also:
    %   SBFSEM.CORE.BOUNDARYMARKER
    %
    % History:
    %   19May2019 - SSP
    % ---------------------------------------------------------------------

    assert(isa(entity, 'sbfsem.core.BoundaryMarker'), 'Input a BoundaryMarker object');
    
    % This function is saved in the data directory, so that's a good first
    % guess at where the boundary marker cache should be saved
    parentDir = fileparts(mfilename('fullpath'));

    if nargin < 2
        dataDir = uigetdir(parentDir, 'Cache folder');
        if isempty(dataDir)
            return;
        end
    else
        assert(isfolder(dataDir), 'dataDir must be a valid directory');
    end

    switch class(entity)
        case 'sbfsem.builtin.INLBoundary'
            markerType = 'INL';
        case 'sbfsem.builtin.GCLBoundary'
            markerType = 'GCL';
        otherwise
            error('Boundary type not recognized!');
    end
    fName = [upper(entity.source), '_', markerType, '.txt'];
    fPath = [dataDir, filesep, fName];
    
    % Check whether boundary marker cache already exists
    if exist(fPath, 'file')
        answer = questdlg(...
            'Boundary marker cache already exists... overwrite?',...
            'Existing file',...
            'Yes', 'No', 'Yes');
        if isempty(answer) || strcmp(answer, 'No')
            return;
        end
    end

    dlmwrite(fPath, entity.markerLocations);
    fprintf('Successfully updated cache file:\n\t%s\n', fPath);
end