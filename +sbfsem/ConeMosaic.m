classdef ConeMosaic < handle
    % CONEMOSAIC
    % 
    % Constructor:
    %   obj = sbfsem.ConeMosaic('source');
    %
    % Properties:
    %   sCones
    %   lmCones
    % Methods:
    %   x = obj.getCones(coneType);
    %   obj.plot(coneType, axHandle);
    %
    % History:
    %   5Jan2017 - SSP - preliminary, messy version
    % ---------------------------------------------------------------------
    properties (SetAccess = private)
        sCones
        lmCones
        lmID
        sID
    end

    properties (Transient = true, Hidden = true)
        ConeClient
    end
    
    properties (Constant = true, Hidden = true)
        CONES = {'LM', 'S'};
        SOURCE = 'NeitzInferiorMonkey';
    end
    
    methods
        function obj = ConeMosaic(source)
            source = validateSource(source);
            if ~strcmp(source, obj.SOURCE)
                warning('Only for NeitzInferiorMonkey');
                return;
            end
            
            obj.ConeClient = sbfsem.io.ConeOData(source);
        end
        
        function x = getCones(obj, coneType)
            coneType = validatestring(upper(coneType), obj.CONES);
            
            IDs = obj.ConeClient.getConeIDs(coneType);
            fprintf('Beginning import of %u IDs\n', numel(IDs)+1);
            switch coneType
                case 'LM'
                    % Hard coded cones
                    [obj.lmCones, obj.lmID] = obj.getDefaults('LM');  
                    % Add the filter returned codes
                    for i = 1:numel(IDs)
                        obj.lmCones = cat(1, obj.lmCones,...
                            obj.getOutline(IDs(i)));
                    end
                    obj.lmID = cat(2, obj.lmID, IDs);
                    x = obj.lmCones;
                case 'S'
                    [obj.sCones, obj.sID] = obj.getDefaults('S');
                    for i = 1:numel(IDs)
                        obj.sCones = cat(1, obj.sCones,...
                            obj.getOutline(IDs(i)));
                    end
                    obj.sID = cat(2, obj.sID, IDs);
                    x = obj.sCones;
            end
        end
        
        function update(obj, coneType)
            coneType = validatestring(upper(coneType), obj.CONES);
            
            IDs = obj.ConeClient.getConeIDs(coneType);
            switch coneType
                case 'LM'
                    newIDs = setdiff(IDs, obj.lmID);
                    if ~isempty(newIDs)
                        for i = 1:numel(newIDs)
                            obj.lmCones = cat(1, obj.lmCones,...
                                obj.getOutline(newIDs(i)));
                            obj.lmID = cat(2, obj.lmID, newIDs(i));
                        end
                    end
                case 'S'
                    newIDs = setdiff(IDs, obj.sID);
                    if ~isempty(newIDs)
                        for i = 1:numel(newIDs)
                            obj.sCones = cat(1, obj.sCones,...
                                obj.getOutline(newIDs(i)));
                            obj.sID = cat(2, obj.sID, newIDs(i));
                        end
                    end
            end
            fprintf('Imported %u new IDs\n', numel(newIDs));
        end
        
        function plot(obj, coneType, ax, tag)
            % PLOT  Plot the mosaic
            if nargin < 3
                fh = figure('Name', 'Cone Outlines');
                ax = axes('Parent', fh);
            end
            if nargin < 4
                tag = '';
            end
            
            switch coneType
                case 'LM'
                    if isempty(obj.lmCones)
                        obj.getCones('LM');
                    end
                    arrayfun(@(x) x.trace('ax', ax,...
                        'EdgeColor', 'k',...,...
                        'Tag', tag,...
                        'FaceColor', 'none'), obj.lmCones);
                case 'S'
                    if isempty(obj.sCones)
                        obj.getCones('S');
                    end
                    arrayfun(@(x) x.trace('ax', ax,...
                        'FaceColor', [0, 0.4, 1],...
                        'FaceAlpha', 0.1,...,...
                        'Tag', tag,...
                        'EdgeColor', [0, 0.4, 1]), obj.sCones);
            end
            
            axis(ax, 'equal');
            axis(ax, 'tight');
        end
        
    end
    
    methods (Access = private)
        function x = getOutline(obj, ID)
            x = sbfsem.core.ClosedCurve(Neuron(ID, obj.SOURCE));
        end
        
        function [x, ID] = getDefaults(obj, coneType)
            switch coneType
                case 'S'
                    ID = 4983;
                    % Later make a for loop or automate if the number of
                    % multiple annotation cones continues to increase.
                    c4983 = Neuron(ID, obj.SOURCE);
                    x = sbfsem.core.ClosedCurve(c4983.geometries(...
                        c4983.geometries.Z == 1701,:));
                case 'LM'
                    ID = 2542;
                    c2542 = Neuron(ID, obj.SOURCE);
                    x = sbfsem.core.ClosedCurve(c2542.geometries(...
                        c2542.geometries.Z == 1687,:));
            end
        end
    end
end