classdef Vector3 < handle
    % VECTOR3
    %
    % Description:
    %   Several helpful 3D vector functions in a single class.
    %   This class keeps them consistent and facilitates testing.
    %
    % History:
    %   18Apr2018 - SSP
    % ---------------------------------------------------------------------
    
    methods
        function obj = Vector3()
            % Do nothing
        end
    end
    
    methods (Static)
        
        function unit_vec = unit(vec)
            % UNIT  A vector divided by the Euclidean distance (L2 norm)
            vec = Vector3.check(vec);
            unit_vec = vec / Vector3.L2(vec);
        end
        
        function vec = check(vec)
            % CHECK
            
            assert(isnumeric(vec),...
                'SBFSEM:Vector3:InvalidType',...
                'Vectors must consist of only numbers');
            assert(ismember(3, size(vec)),...
                'SBFSEM:Vector3:InvalidSize',...
                '3D vectors must be Nx3 or 3xN!');
            if size(vec,2) ~= 3
                vec = vec'; % revisit this
            end
        end
        
        function dist = L2(vec1, vec2)
            % L2 
            %   Fast version of Euclidean distance, L2 norm
            %
            % Inputs:
            %   vec1        Vector (Nx3)
            % Optional inputs:
            %   vec2        Vector (1x3) or matrix (Nx3). Default = (0,0,0)
            % -------------------------------------------------------------
            
            vec1 = Vector3.check(vec1);
            
            if nargin == 1
                x = vec1(:, 1); y = vec1(:, 2); z = vec1(:, 3);
            else
                vec2 = Vector3.check(vec2);
                if size(vec2, 1) ~= size(vec1, 1)
                    vec2 = repmat(vec1, [size(vec2, 1), 1]);
                end
                x = bsxfun(@minus, vec1(:,1), vec2(:,1));
                y = bsxfun(@minus, vec1(:,2), vec2(:,2));
                z = bsxfun(@minus, vec1(:,3), vec2(:,3));
            end
            dist = sqrt(x.^2 + y.^2 + z.^2); 
        end
        
        function plot(vec, varargin)
            % PLOT
            
            vec = Vector3.check(vec);
            
            z = zeros(size(vec));
            plot3([z(:,1) vec(:,1)], [z(:,2) vec(:,2)], [z(:,3) vec(:,3)],...
                varargin{:});
        end
        
    end
end