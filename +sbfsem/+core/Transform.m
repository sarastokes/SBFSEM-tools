classdef Transform < handle
    % TRANSFORM
    % Work in progress!

	properties (SetAccess = protected)
		name
		filePath
	end

	methods
		function obj = Transform()
			% Do nothing
		end
	end

	methods (Static)
		function dataDir = getDataDir()
			% GETDATADIR  Returns data folder

			dataDir = [fileparts(fileparts(fileparts(...
				mfilename('fullpath')))), '\data\'];
		end
	end
end
