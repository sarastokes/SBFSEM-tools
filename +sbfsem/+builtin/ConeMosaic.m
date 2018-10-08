classdef ConeMosaic < handle
    % CONEMOSAIC
    %
    % Constructor:
    %   obj = sbfsem.builtin.ConeMosaic(source, importCones);
    %
    % Inputs:
    %   source          Volume name or abbreviation
    % Optional inputs:
    %   importCones     Auto import all cones (default = true)
    %
    % Properties:
    %   sCones      S-cone traces
    %   lmCones     LM-cone traces
    %   uCones      Undefined cone traces
    %   lmID        LM-cone IDs
    %   sID         S-cone IDs
    %   uID         Undefined cone IDs
    %
    % Methods:
    %   obj.getCones(coneType);
    %   obj.getAll();
    %   obj.update(coneType);
    %   obj.updateAll();
    %   obj.plot(coneType, axHandle);
    %   obj.plotAll();
    %   obj.info();
    %
    % Notes:
    %   Only available for NeitzInferiorMonkey currently. This function
    %   extracts closed curve traces of cones by querying for structures
    %   with the labels 'lmTRACE', 'sTRACE', 'uTRACE' for LM-cones, S-cones
    %   and unidentified cones, respectively. These structures may have
    %   other disc annotations but must only have one closed curve. For
    %   now, structures with multiple closed curves must be hard-coded into
    %   the getDefaults() function
    %
    % See also:
    %   SBFSEM.IO.CONEODATA, SBFSEM.CORE.CLOSEDCURVE
    %
    % History:
    %   5Jan2018 - SSP - preliminary, messy version
    %   8Feb2018 - SSP - added option for undefined (U) cone type
    %   16Feb2018 - SSP - update() now checks for defaults, uID bug fix
    %   7Oct2018 - SSP - added load from cache option
    % ---------------------------------------------------------------------
    
    properties (SetAccess = private)
        % The ClosedCurve structures representing each cone
        sCones
        lmCones
        uCones
        % Cone trace ID numbers
        lmID
        sID
        uID
    end
    
    properties (Transient = true, Hidden = true)
        ConeClient
    end
    
    properties (Constant = true, Hidden = true)
        CONES = {'LM', 'S', 'U'};
        SOURCE = 'NeitzInferiorMonkey';
    end
    
    methods
        function obj = ConeMosaic(source, importCones)
            % CONEMOSAIC  Constructor
            % Input:
            %   source      volume name or abbreviation (char)
            
            source = validateSource(source);
            if ~strcmp(source, obj.SOURCE)
                warning('Only for NeitzInferiorMonkey');
                return;
            end

            if nargin < 2
                importCones = true;
            end
            
            obj.ConeClient = sbfsem.io.ConeOData(source);
            if importCones
                obj.getAll();
            end
        end
        
        function info(obj)
            % INFO  Print information about the cone mosaic to cmd line
            
            totalCones = numel(obj.lmID) + numel(obj.sID) + numel(obj.uID);
            
            if totalCones == 0
                disp('Empty cone mosaic');
            else
                fprintf('Cone Mosaic with %u cones\n', totalCones);
                if ~isempty(obj.lmID)
                    fprintf('\t%u LM-cones\n', numel(obj.lmID));
                end
                if ~isempty(obj.sID)
                    fprintf('\t%u S-cones\n', numel(obj.sID));
                end
                if ~isempty(obj.uID)
                    fprintf('\t%u unidentified cones\n', numel(obj.uID));
                end
            end
        end
        
        function getAll(obj)
            % GETALL  Loads all cone traces
            
            for i = 1:numel(obj.CONES)
                obj.getCones(obj.CONES{i});
            end
        end
        
        function x = getCones(obj, coneType)
            % GETCONES  Load cones of a specific type
            % Input:
            %   coneType        which cone type ('LM', 'S', 'U');
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
                case 'U'
                    [obj.uCones, obj.uID] = obj.getDefaults('U');
                    for i = 1:numel(IDs)
                        obj.uCones = cat(1, obj.uCones,...
                            obj.getOutline(IDs(i)));
                    end
                    obj.uID = cat(2, obj.uID, IDs);
                    x = obj.uID;
            end
        end
        
        
        function update(obj, coneType)
            % UPDATE
            
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
                case 'U'
                    newIDs = setdiff(IDs, obj.uID);
                    if ~isempty(newIDs)
                        for i = 1:numel(newIDs)
                            obj.uCones = cat(1, obj.uCones,...
                                obj.getOutline(newIDs(i)));
                            obj.uID = cat(2, obj.uID, newIDs(i));
                        end
                    end
            end
            fprintf('Imported %u new IDs\n', numel(newIDs));
        end
        
        function updateAll(obj)
            % UPDATEALL
            
            for i = 1:numel(obj.CONES)
                obj.update(obj.CONES{i});
            end
        end
        
        function plot(obj, coneType, ax, tag)
            % PLOT  Plot the mosaic
            %
            % Inputs:
            %   coneType        either 'LM', 'S', 'U'
            % Optional inputs:
            %   ax              axes handle
            %   tag             custom tag for patch obj
            % -------------------------------------------------------------
            if nargin < 3 || isempty(ax)
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
                case 'U'
                    if isempty(obj.uCones)
                        obj.getCones('U');
                    end
                    arrayfun(@(x) x.trace('ax', ax,...
                        'FaceColor', 'none',...
                        'Tag', tag,...
                        'EdgeColor', 'k'), obj.uCones);
            end
            
            axis(ax, 'equal');
            axis(ax, 'tight');
        end
        
        function plotAll(obj, ax, tag)
            if nargin < 2
                fh = figure('Name', 'Cone Outlines');
                ax = axes('Parent', fh);
            end
            
            if nargin < 3
                tag = '';
            end
            
            for i = 1:numel(obj.CONES)
                obj.plot(obj.CONES{i}, ax, tag);
            end
        end
        
    end
    
    methods (Access = private)
        function x = getOutline(obj, ID)
            % GETOUTLINE  Create a ClosedCurve obj from cone trace
            x = sbfsem.builtin.ClosedCurve(Neuron(ID, obj.SOURCE));
        end
        
        function [x, ID] = getDefaults(obj, coneType)
            % GETDEFAULTS  Get default annotations
            switch coneType
                case 'S'
                    ID = 4983;
                    % Later make a for loop or automate if the number of
                    % multiple annotation cones continues to increase.
                    c4983 = Neuron(ID, obj.SOURCE);
                    x = sbfsem.builtin.ClosedCurve(c4983.geometries(...
                        c4983.geometries.Z == 1701,:));
                case 'LM'
                    ID = 2542;
                    c2542 = Neuron(ID, obj.SOURCE);
                    x = sbfsem.builtin.ClosedCurve(c2542.geometries(...
                        c2542.geometries.Z == 1686,:));
                case 'U'
                    x = []; ID = [];
                otherwise
                    warning('CONEMOSAIC: Unknown coneType - %s', coneType);
            end
        end
    end

    methods (Static)
        function obj = fromCache(source)
            source = validateSource(source);

            cachedMosaic = load([...
                fileparts(fileparts(fileparts(mfilename('fullpath')))),...
                filesep, 'data', filesep,...
                upper(source), '_ConeMosaic.mat']);
            
            obj = cachedMosaic.coneMosaic;
        end
    end
end