classdef Volumes < handle
    % VOLUMES
    %
    % Description:
    %   Standardizes frequently accessed volume features
    %
    % See also:
    %   VALIDATESOURCE
    %
    % History:
    %   30Nov2018 - SSP
    % ---------------------------------------------------------------------
    
    enumeration
        NeitzInferiorMonkey
        NeitzTemporalMonkey
        MarcRC1
    end
    
    methods
        function tf = hasCones(obj)
            % HASCONES  Whether cone outlines have been traced
            if obj == sbfsem.builtin.Volumes.NeitzInferiorMonkey
                tf = true;
            else
                tf = false;
            end
        end
        
        function tf = hasBoundary(obj)
            % HASBOUNDARY  Whether IPL boundary markers exist
            if obj == sbfsem.builtin.Volumes.MarcRC1
                tf = false;
            else
                tf = true;
            end
        end
    end
    
    methods (Static)
        function obj = fromChar(str)
            % FROMCHAR  Create object from volume name
            source = validateSource(str);
            import sbfsem.builtin.Volumes;
            switch source
                case 'NeitzInferiorMonkey'
                    obj = Volumes.NeitzInferiorMonkey;
                case 'NeitzTemporalMonkey'
                    obj = Volumes.NeitzTemporalMonkey;
                case 'RC1'
                    obj = Volumes.MarcRC1;
            end
            
        end
    end
    
    
end