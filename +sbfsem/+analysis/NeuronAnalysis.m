classdef (Abstract) NeuronAnalysis < handle
    % NEURONANALYSIS  This class will make population data on common
    % analyses easier to manage by organizing input parameters and results.
    %
    % Properties:
    %       data                    Struct, table or map
    %       actions                 Logs all activity
    %       target                  Object being analyzed
    %       DisplayName             Name used as reference
    %
    % Methods:
    %       append(obj, newData);    
    %       desribe(obj, str);
    % Abstract methods:
    %       doAnalysis(obj)         Main data analysis method
    %       visualize(obj)          Display analysis results
    %
    % 25Aug2017 - SSP

    properties (SetAccess = protected)
        data
        ID
    end

    properties (Access = private)
        actions
    end

    properties (Transient = true)
        target        
    end
    
    methods (Abstract)
        doAnalysis(obj);
        visualize(obj);
    end
    
    methods
        function obj = NeuronAnalysis(target)
            % NEURONANALYSIS
            if nargin > 0
                % might eventually leave attribute validation to subclasses
                validateattributes(target, {'sbfsem.Neuron', 'sbfsem.NeuronGroup'}, {});
                % Target is a transient property
                obj.target = target;
                % Save only the cell ID numbers with analysis
                if isa(target, 'sbfsem.Neuron')
                    obj.ID = obj.target.ID;
                else
                    % TODO: Revist this after writing NeuronGroup code
                   obj.ID = obj.target.IDs;
                end
            else
                obj.target = [];
            end

            obj.actions = [datestr(now), ' - created'];
        end
    end
    
    methods
        function append(obj, newData)
            % APPEND  Add a completed analysis to existing object
            str = [datestr(now), ' - appended new ', class(newData), '\n'];
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
        end
    end
end
