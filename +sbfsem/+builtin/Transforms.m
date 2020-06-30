classdef Transforms
% TRANSFORMS
%
% Description
%   Methods and enumeration for transforms to incoming XYZ data
%
% History:
%   05Aug2019 - SSP - Created
%   30Jun2020 - SSP - Refactored, moved in code from StructureAPI
% -------------------------------------------------------------------------

    enumeration
        Standard        % Scale by volumeScale property, convert um -> nm
        Custom          % User-defined transformation
        None            % No transformation
    end

    methods (Static)
        function obj = fromStr(str)
            import sbfsem.builtin.Transforms;

            switch lower(str)
                case 'standard'
                    obj = Transforms.Standard;
                case {'custom', 'local'}
                    obj = Transforms.Custom;
                case 'none'
                    obj = Transforms.None;
                otherwise
                    fprintf('Transform %s not recognized. No transform will be applied!', str);
                    obj = Transforms.None;
            end
        end

        function value = scale(data, volumeScale)
            % SCALE  by volume dimensions and convert to microns

            % Convert volumeScale from nm to microns
            volumeScale = volumeScale ./ 1e3;

            switch size(data, 2)
                case 3      % XYZ
                    value = bsxfun(@times, data, volumeScale);
                case 1      % Radius
                    value = data * volumeScale(1);
            end
        end

        function [x, y] = translate(xyz, source)
            % TRANSLATE  Shift XY to compensate for registration errors
            dataDir = [fileparts(fileparts(fileparts(...
                mfilename('fullpath')))), filesep, 'data'];
            fileName = ['XY_OFFSET_', upper(source), '.txt'];
            xyOffset = dlmread([dataDir, filesep, fileName]);
            x = xyz(:, 1) + xyOffset(xyz(:, 3), 2);
            y = xyz(:, 2) + xyOffset(xyz(:, 3), 3);
        end

        function [x, y] = nasalMonkey(xyz, scaleFactors)
            % NASALMONKEY  Attempt to fix nornir's "off by one(?)" error
            zOffset = scaleFactors(3) * abs(xyz(:, 3) - 1177);
            x = xyz(:, 1) - (zOffset .* (xyz(:, 1) / scaleFactors(1)));
            y = xyz(:, 2) - (zOffset .* (xyz(:, 2) / scaleFactors(2)));
        end

        function tf = checkViking(neuron)
            % CHECKVIKING for a some oddities in the database
            assert(isa(neuron, 'sbfsem.core.StructureAPI'),...
                'Input a StructureAPI object');

            if neuron.nodes.VolumeX == neuron.nodes.X ...
                    && neuron.nodes.VolumeY == neuron.nodes.Y
                tf = false;
            else
                tf = true;
            end
        end
    end
end
