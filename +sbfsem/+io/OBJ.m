classdef OBJ < handle
    % OBJ
    %
    % Description:
    %   Import meshes as .obj files
    %
    % Constructor:
    %   obj = sbfsem.io.OBJ(fName)
    %   p = patch(obj.FV, varargin);
    %
    % Inputs:
    %   fName           file path and name of .obj file
    %
    % History:
    %   12Feb2021 - SSP
    % ---------------------------------------------------------------------

    properties (SetAccess = private)
        fName 
        FV 
    end

    methods 
        function obj = OBJ(fName)
            obj.fName = fName;
            
            obj.import();
        end
    end

    methods (Access = private)
        
        function import(obj)
            fprintf('Reading .obj file... ');
            x = readObj(obj.fName);
            obj.FV = struct('Faces', x.f.v, 'Vertices', x.v);
            fprintf('Done\n');
        end
    end
end