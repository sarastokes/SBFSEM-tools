classdef ImageNode < handle
% IMAGENODE  Single image in an image stack
%
% Description:
%   Meant to be called from ImageStack, not used alone
%
% See also:
%   SBFSEM.IMAGE.IMAGESTACK, IMAGESTACKAPP
%
% History:
%   29Sept2017 - SSP
%   4Feb2018 - SSP - node2matrix function
% -------------------------------------------------------------------------

	properties (Access = public)
		savePath					% New save path
		name 						% Readable name	

		next 
		previous
	end

	properties (SetAccess = private, GetAccess = public)
		filePath					% Original file path
		imData						% Image
	end

	methods
		function obj = ImageNode(filePath, varargin)

			% where the imported image is saved
			obj.filePath = filePath;

			ip = inputParser();
			ip.CaseSensitive = false;
			% image data
			addParameter(ip, 'imData', []);
			% image display name
			addParameter(ip, 'name', [], @ischar);
			% where the edited image is saved
			addParameter(ip, 'savePath', [], @isdir);
			parse(ip, varargin{:});
			obj.savePath = ip.Results.savePath;

			% Get image data from filepath
			if isempty(ip.Results.imData)
				obj.imData = imread(filePath);
			else
				obj.imData = ip.Results.imData;
			end

			% Use filename if other name isn't specified
			if isempty(ip.Results.name)
				tmp = strsplit(obj.filePath, filesep);
				obj.name = tmp{end};
			else
				obj.name = ip.Results.name;
			end
		end

		function setName(obj, newName)
			if ischar(newName)
				obj.name = newName;
			elseif isnumeric(newName)
				obj.num2str(newName);
			end
		end

		function setImage(obj, imData, writeFlag)
			% SETIMAGE  Set the image
			% Inputs: 	imData		image
			%			writeFlag	[false] tf overwrite

			if nargin < 3
				writeFlag = false;
			end

			if isempty(obj.imData)
				obj.imData = imData;
				return;
			else % check overwrite privileges
				if writeFlag
					obj.imData = imData;
				else
					warning('Overwrite privileges must be true');
				end
			end
        end
        
        function mat = node2matrix(obj)
            % NODE2MATRIX  
            mat = obj.imData;
        end

		function fh = show(obj, ax)
			% SHOW  Display image
			% Optional inputs:
			%	ax 			axis handle
			if nargin == 2
				validateattributes(ax, {'handle'}, {});
				fh = ax.Parent;
			else
				fh = figure();
				ax = axes('Parent', fh);
			end
			imshow(obj.imData, 'Parent', ax);			
		end

		function imupdate(obj, check)
			% IMUPDATE  Update with image from file
			% INPUTS:	check	[false]  compare images
			if nargin < 2
				check = false;
			end

			oldImage = obj.imData;
			newImage = imread(obj.filePath);
			if check
				obj.imcompare(newImage);
			end
			obj.imData = newImage;
		end

		function imcompare(obj, newImage)
			% IMCOMPARE  Compare existing image to new one
			imshowpair(obj.imData, newImage, 'montage');
		end

		% Set/get functions
		function set.next(obj, next)
			obj.next = next;
		end

		function next = get.next(obj)
			next = obj.next;
		end

		function set.previous(obj, previous)
			obj.previous = previous;
		end

		function previous = get.previous(obj)
			previous = obj.previous;
		end
	end
end