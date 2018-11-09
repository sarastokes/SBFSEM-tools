classdef STL < handle
	% STL
	%
	% Description:
	%	Export meshes as .stl files
	%
	% Constructor:
	%	obj = sbfsem.io.STL()
	%
	% Inputs:
	%	hObj 		Neuron
	% Options:
	%	fName 		File name and path to save, otherwise dialog
	% 	See stlwrite for remaining options
	%
	% History:
	%	8Nov2018 - SSP
	% --------------------------------------------------------------------

	properties (SetAccess = private)
		fName
		FV
	end

	methods
		function obj = STL(neuron, fName, varargin)

			if isa(neuron, 'sbfsem.core.StructureAPI')
					neuron.build();
					obj.FV = neuron.model.allFV;
            elseif isa(neuron, 'matlab.graphics.primitive.Patch')
					obj.FV = struct('Faces', neuron.Faces,... 
									'Vertices', neuron.Vertices);
            else
				error('SBFSEM:IO:STL:InvalidInput',...
					'Must provide Neuron object or patch');
			end

			if nargin < 2
				obj.fName = uiputfile();
			else
				obj.setPath(fName);
			end

			obj.export(varargin{:});

            fprintf('Saving to %s\n', obj.fName);
		end
	end

	methods (Access = private)
		function export(obj, varargin)
			stlwrite(obj.fName, obj.FV, varargin{:});
		end

	    function setPath(obj, fName)
            % SETPATH  Set the save directory and name
            
            % If there are no fileseps, it's just a filename
            if ~mycontains(fName, filesep)
                fPath = uigetdir();
                if isempty(fPath)
                    % Leave if user presses 'Cancel'
                    return
                else
                    fName = [fPath, filesep, fName];
                end
            end
            
            % Check for correct file extension
            if strcmp(fName(end-2:end), '.stl')
                fName = [fName, '.stl'];
            end
            obj.fName = fName;
        end
    end
end