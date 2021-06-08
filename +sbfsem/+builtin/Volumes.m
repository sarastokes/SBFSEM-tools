classdef Volumes < handle
    % VOLUMES
    %
    % Description:
    %   Standardizes frequently accessed volume features
    %
    % See also:
    %   VALIDATESOURCE, GETSERVICEROOT
    %
    % History:
    %   30Nov2018 - SSP
    %   09Dec2019 - SSP - Added NeitzNasalMonkey
    %   31Jan2020 - SSP - Added 3 new Marc lab volumes
    %   08May2021 - JAK - Added NeitzCped
    % ---------------------------------------------------------------------
    
    enumeration
        NeitzInferiorMonkey
        NeitzNasalMonkey
        NeitzTemporalMonkey
        NeitzCped
        MarcRC1
        MarcRPC1
        MarcRC2
        MarcRPC2
        DemoVolume
    end
    
    methods
        function tf = isOData(obj)
            % ISODATA  Returns whether data source is OData compatible
            if obj == sbfsem.builtin.Volumes.DemoVolume
                tf = false;
            else
                tf = true;
            end
        end

        function url = getServiceRoot(obj)
            % GETSERVICEROOT  Return base OData query URL
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
            import sbfsem.builtin.Volumes;
            switch obj
                case {Volumes.NeitzTemporalMonkey, Volumes.NeitzInferiorMonkey, Volumes.NeitzNasalMonkey, Volumes.MarcRC1}
                    tf = true;
                otherwise
                    tf = false;
            end
        end
        
        function tf = hasCustomTransform(obj)
            % HASCUSTOMTRANSFORM  Whether volume has a transform
            import sbfsem.builtin.Volumes;
            switch obj
                case {Volumes.NeitzInferiorMonkey, Volumes.NeitzNasalMonkey}
                    tf = true;
                otherwise
                    tf = false;
            end
        end
        
        function n = nSections(obj)
            import sbfsem.builtin.Volumes;
            switch obj
                case Volumes.NeitzInferiorMonkey
                    n = 1893;
                case Volumes.NeitzNasalMonkey
                    n = 2354;
                case Volumes.NeitzTemporalMonkey
                    n = 837;
                otherwise
                    error('Section count not yet implemented for %s', char(obj));
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
                case 'NeitzCped'
                    obj = Volumes.NeitzCped;
                case 'RC1'
                    obj = Volumes.MarcRC1;
                case 'RC2'
                    obj = Volumes.MarcRC2;
                case 'RPC1'
                    obj = Volumes.MarcRPC1;
                case 'RPC2'
                    obj = Volumes.MarcRPC2;
            end
        end
    end
end