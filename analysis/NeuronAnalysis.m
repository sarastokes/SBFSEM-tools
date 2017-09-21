classdef NeuronAnalysis < handle
    % NEURONANALYSIS  This class will make population data on common
    % analyses easier to manage by organizing input parameters and results.
    %
    % 25Aug2017 - SSP - created


    properties (SetAccess = protected)
        data % structure if 1, table if more
    end
    properties (Access = private)
        actions % logs all activity
    end
    properties (Transient)
        target % object being analyzed: neuron, mosaic, simneuron        
    end
    properties (Abstract)
        keyName % reference in Neuron/Mosaic analysis containers.Map
    end


    methods
        function obj = NeuronAnalysis(target)
            % NEURONANALYSIS
            if nargin > 0
                % might eventually leave attribute validation to subclasses
                validateattributes(target, {'Neuron', 'Mosaic'}, {});
                obj.target = target;
            else
                obj.target = [];
            end

            obj.actions = [datestr(now), ' - created'];
        end % constructor
    end % methods
    
    methods (Abstract)
        doAnalysis(obj) % main analysis method
        visualize(obj) % display analysis results
    end % abstract methods
    
    methods
        function append(obj, newData)
            % APPEND  Add a completed analysis to existing object
            str = [datestr(now) ' - appended new ' class(newData) '\n'];
            if isstruct(newData)
                newData = struct2table(newData);
            else isa(newData, 'NeuronAnalysis')
                str = [str, '\nBEGIN APPENDED LOG\n',...
                    newData.actions, 'END APPENDED LOG\n\n'];
                newData = struct2table(newData.data);
            end
            if isstruct(obj.data)
                obj.data = struct2table(obj.data);
            end
            obj.data = [obj.data; newData];
            obj.actions = cat(2, obj.actions, str);
        end % append

        function describe(obj, str)
            % DESCRIBE  Add a short string describing the analysis
            obj.description = str;
        end % describe
    end % protected methods
end % classdef
