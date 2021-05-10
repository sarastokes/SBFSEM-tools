function FV = clipMeshByVertices(FV, idx)
    % CLIPMESHVERTICES
    % 
    % Syntax:
    %   FV = clipMeshByVertices(FV, idx)
    %
    % Inputs:
    %   FV      Struct with 'faces' and 'vertices' OR patch handle
    %   idx     Vertices to remove
    %
    % Outputs:
    %   FV      New struct with 'faces' and 'vertices'
    %           If FV is a patch handle and no output, will apply to patch
    %
    % See also:
    %   CLIPMESH, CLIPMESHBYSTRATIFICATION
    %
    % History:
    %   12Dec2020 - SSP
    % ---------------------------------------------------------------------

    if islogical(idx)
        idx = find(idx);
    end

    renderNow = false;
    
    if isa(FV, 'matlab.graphics.primitive.Patch')
        p = FV;
        FV = struct(...
            'faces', get(p, 'Faces'), ...
            'vertices', get(p, 'Vertices'));

        if nargout == 0
            % Change the render to match output
            renderNow = true;
        end
    end

    verts = FV.vertices;
    faces = FV.faces;
    
    fprintf('Clipping out %u vertices\n', nnz(idx));

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
