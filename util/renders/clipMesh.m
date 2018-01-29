function FV = clipMesh(FV, Z, over)
    % CLIPMESH 
    %
    % Description:
    %   Remove faces and vertices above/below a cutoff point
    %
    % Inputs:
    %   FV      Struct with 'faces' and 'vertices' OR patch handle
    %   pt      Cutoff point
    % Optional inputs:
    %   over    Set true to keep points greater than pt (default = true)
    %
    % Outputs:
    %   FV      New struct with 'faces' and 'vertices'
    %           If FV is a patch handle and no output, will apply to patch
    %
    % Note:
    %   For sbfsem-tools, over=true means keeping the sclerad faces.
    %
    % History:
    %   9Jan2018 - SSP
    %   28Jan2018 - SSP - Added trimMesh to remove clipped vertices
    % ---------------------------------------------------------------------
    
    renderNow = false;
    
    if nargin < 3
        over = true;
    end
    
    if isa(FV, 'matlab.graphics.primitive.Patch')
        p = FV;
        FV = struct(...
            'faces', get(p, 'Faces'),...
            'vertices', get(p, 'Vertices'));
        if nargout == 0
            % Change the render to match output
            renderNow = true;
        end
    end
    
    verts = FV.vertices;
    faces = FV.faces;
    
    % Get the indices of vertices to be clipped out
    if over
        rows = verts(:,3) < Z;
    else
        rows = verts(:,3) > Z;
    end
    cutVerts = find(rows);
    fprintf('Clipping out %u of %u vertices\n', nnz(rows), numel(rows));
    
    % Find which faces contain one or more clipped vertices
    cutFaceRows = [];
    for i = 1:size(faces,1)
        if ~isempty(intersect(faces(i,:), cutVerts))
            cutFaceRows = [cutFaceRows, i]; %#ok
        end
    end

    % Remove the faces with vertices over/under the cutoff point
    FV.faces(cutFaceRows,:) = [];
    % Trim out the unused vertices
    [FV.vertices, FV.faces] = trimMesh(FV.vertices, FV.faces);
    
    if renderNow
        set(p, 'Faces', FV.faces, 'Vertices', FV.vertices);
    end