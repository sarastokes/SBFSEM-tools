classdef ConeTrace < handle
    
    properties (SetAccess = private)
        Z
        outline
        coneType
    end
    
    properties (Constant = true, Hidden = true)
        PIX2MICRON = 0.2276;
    end
    
    methods 
        function obj = ConeTrace(outline, Z, coneType)
            if nargin < 3
                obj.coneType = 'unknown';
            else
                obj.setConeType(coneType);
            end
            
            obj.Z = Z;
            
            obj.outline = outline;           
        end
        
        function setConeType(obj, coneType)
            obj.coneType = validatestring(upper(coneType), {'S', 'LM'});
        end
        
        function Zum = getZum(obj, source)
            volumeScale = getODataScale(source); % nm
            volumeScale = volumeScale*1e-3; % microns
            
            Zum = obj.Z * volumeScale(3);
        end
    end
end