classdef Transforms

    enumeration
        SBFSEMTools
        Viking
        Merged
        None
    end

    methods (Static)
        function obj = fromStr(str)
            import sbfsem.core.Transforms;

            switch lower(str)
                case 'sbfsemtools'
                    obj = Transforms.SBFSEMTools;
                case 'viking'
                    obj = Transforms.Viking;
                case 'merged'
                    error('Not yet implemented');
                case 'none'
                    obj = Transforms.None;
                otherwise
                    fprintf('Transform %s not recognized. No transform will be applied!', str);
                    obj = Transforms.None;
            end
        end

        function tf = hasViking(neuron)

            assert(isa(neuron, 'NeuronAPI'), 'Input a neuron object');

            if neuron.nodes.VolumeX == neuron.nodes.X ...
                    && neuron.nodes.VolumeY == neuron.nodes.Y
                tf = false;
            else
                tf = true;
            end
        end
    end
end
