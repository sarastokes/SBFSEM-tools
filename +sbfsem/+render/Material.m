classdef Material < handle
    % MATERIAL
    %
    % Description:
    %	Consistent interface for setting render properties
    %
    % Constructor:
    %	obj = Material(gObj, varargin)
    %
    % Properties
    %	gObj 		Handle to graphics object
    %
    % Methods
    %	unmatched = obj.set(varargin);
    %       Set properties defined by key/value pairs. Optionally returns
    %       the unmatched key/values or initial non-char value arguments
    %	obj.view();                         
    %       Open matlab property inspector
    %
    % History:
    %	19Apr2018 - SSP
    % ----------------------------------------------------------------------
    
    properties (Access = private)
        gObj            % Handle to parent graphic object
    end
    
    methods
        function obj = Material(gObj, varargin)
            % MATERIAL  Constructor
            assert(ishandle(gObj),...
                'SBFSEM:render:Material:InvalidInput',...
                'Input a graphics object hande');
            obj.gObj = gObj;
            
            if nargin > 1
                obj.set(varargin{:});
            end
        end
        
        function view(obj)
            % VIEW  Opens user interface for setting properties
            inspect(obj.gObj);
        end
        
        function unmatched = set(obj, varargin)
            % SET
            
            % Search for initial inputs that aren't key value pairs. If a
            % value argument is type char, it will be interpreted as the
            % key for the next value.
            ind = 1;
            while ~ischar(varargin{ind})
                ind = ind + 1;
            end
            unmatched = varargin(1:ind-1);
            for i = ind:2:numel(varargin)
                success = obj.setIfExist(varargin{i}, varargin{i+1});
                % If key didn't match a property, add the key/value pair to
                % the unmatched output.
                if ~success
                    unmatched = cat(1, unmatched, varargin(i:i+1));
                end
            end           
        end
        
        function disp(obj)
            % DISP      Custom commandline display
            if ~isempty(obj.gObj)
                fprintf('Material for %s\n', class(obj.gObj));
            else
                fprintf('Material for %s\n', obj.gObj.Tag);
            end
        end
    end
    
    methods (Access = private)
        function tf = setIfExist(obj, key, value)
            % SETIFEXIST  Sets a property (key) to value, if existing
            if isprop(obj.gObj, key)
                set(obj.gObj, key, value);
                tf = true;
            else
                warning('SBFSEM:render:Material:InvalidInput',...
                    'Invalid property %s', key);
                tf = false;
            end
        end
    end
end