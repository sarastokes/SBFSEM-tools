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
    %   9Dec2019 - SSP - Added NeitzNasalMonkey
    % ---------------------------------------------------------------------
    
    enumeration
        NeitzInferiorMonkey
        NeitzNasalMonkey
        NeitzTemporalMonkey
        MarcRC1
    end
    
    methods
        function url = getServiceRoot(obj)
            url = getServiceRoot(char(obj));
        end

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
            if obj == sbfsem.builtin.Volumes.MarcRC1 || obj.sbfsem.builtin.Volumes.NeitzNasalMonkey
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
                case 'NeitzNasalMonkey'
                    obj = Volumes.NeitzNasalMonkey;
                case 'NeitzTemporalMonkey'
                    obj = Volumes.NeitzTemporalMonkey;
                case 'RC1'
                    obj = Volumes.MarcRC1;
            end
            
        end
    end
    
    
end