classdef SomaView < handle
% SOMAVIEW
%
% Description:
%   Small class for handling somas of multiple neurons
%
% Constructor:
%   obj = SomaView(source)
%
% Input:
%   source      volume name or abbreviation
%
% Methods:
%   obj.add(neurons)
%   obj.plotSomas();
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        neurons
        IDs
        source
    end

    methods
        function obj = SomaView(source)
            % SOMAVIEW
            %
            % Input:
            %   source      Volume name or abbreviation
            obj.neurons = [];
            obj.IDs = [];
            obj.source = validateSource(source);
        end

        function add(obj, neurons)
            % ADD
            for i = 1:numel(neurons)
                if iscell(neurons)
                    obj.parseNeuron(neurons{i});
                else
                    obj.parseNeuron(neurons(i));
                end
            end
        end

        function plotSomas(obj, varargin)
            % PLOTSOMAS
            ip = inputParser();
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ax', [], @ishandle);
            parse(ip, varargin{:});
            ax = ip.Results.ax;

            if isempty(ax)
                fh = figure('Name', 'SomaView',...
                    'Renderer', 'painters');
                ax = axes('Parent', fh); hold(ax, 'on');
            end

            for i = 1:numel(obj.neurons)
                vissoma(obj.neurons(i), 'ax', ax, ip.Unmatched);
            end
        end
    end

    methods (Access = private)
        function parseNeuron(obj, neuron)
            % PARSENEURON
            if isa(neuron, 'NeuronAPI')
                if ismember(neuron.ID, obj.IDs)
                    return
                end
                obj.neurons = cat(1, obj.neuron, neuron);
                obj.IDs = cat(1, obj.IDs, neuron.ID);
            elseif isnumeric(neuron)
                if ismember(neuron, obj.IDs)
                    return
                end
                obj.neurons = cat(1, obj.neurons,...
                    Neuron(neuron, obj.source));
                obj.IDs = cat(1, obj.IDs, obj.neurons(end).ID);
            end
        end
    end
end
