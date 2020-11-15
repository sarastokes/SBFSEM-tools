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
    %   9Dec2019 - SSP - Added NeitzNasalMonkey
    %   31Jan2020 - SSP - Added 3 new Marc lab volumes
    % ---------------------------------------------------------------------
    
    enumeration
        NeitzInferiorMonkey
        NeitzNasalMonkey
        NeitzTemporalMonkey
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
                case {Volumes.NeitzTemporalMonkey, Volumes.NeitzInferiorMonkey, Volumes.MarcRC1, Volumes.NeitzNasalMonkey}
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