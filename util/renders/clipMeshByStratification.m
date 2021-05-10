function FV = clipMeshByStratification(FV, source, zCutoff, keepAbove)
    % CLIPMESHBYSTRATIFICATION
    % 
    % Syntax:
    %   FV = clipMeshByStratification(FV, source, zCutoff, keepAbove)
    %
    %
    % Inputs:
    %   FV          Struct with 'faces' and 'vertices' OR patch handle
    %   source      Volume name or abbreviation
    %   zCutoff     Cutoff point (in % stratification depth)
    % Optional inputs:
    %   keepAbove   logical [default = true]
    %       Set true to keep points greater than zCutoff
    %
    % Outputs:
    %   FV      New struct with 'faces' and 'vertices'
    %           If FV is a patch handle and no output, will apply to patch
    %
    % See also:
    %   CLIPMESH
    %
    % History:
    %   27Nov2020 - SSP - Adapted from clipMesh
    % ---------------------------------------------------------------------


    if nargin < 3
        keepAbove = true;
    end
    renderNow = false;

    if isa(FV, 'matlab.graphics.primitive.Patch')
        p = FV;
        FV = struct(...
            'faces', get(p, 'Faces'),...
            'vertices', get(p, 'Vertices'));
        if nargout == 0
            renderNow = true;
        end
    end

    verts = FV.vertices;
    faces = FV.faces;

    d = micron2ipl(verts, source);

    % Get the indices of the vertices to be clipped out
    if keepAbove
        idx = d < zCutoff;
    else
        idx = d > zCutoff;
    end
    cutVerts = find(idx);
    fprintf('Clipping out %u of %u vertices\n', nnz(idx), numel(idx));

    % Find which faces contain one or more clipped vertices
    cutFacesIdx = [];
    for i = 1:size(faces, 1)
        if ~isempty(intersect(faces(i, :), cutVerts))
            cutFacesIdx = [cutFacesIdx, i]; %#ok
        end
    end

    % Remove the faces with vertices over/under the cutoff point
    FV.faces(cutFacesIdx, :) = [];
    % Trim out the unused vertices
    [FV.vertices, FV.faces] = trimMesh(FV.vertices, FV.faces);

    if renderNow
        set(p, 'Faces', FV.faces, 'Vertices', FV.vertices);
    end
