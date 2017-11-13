classdef ImageNode < sbfsem.image.Node
% IMAGENODE  Single image in an image stack
% Meant to be called from ImageStack, not used alone
%
% 29Sept2017 - SSP

	properties (SetAccess = private, GetAccess = public)
		filePath
	end

	methods 
		function obj = ImageNode(filePath, varargin)
			obj@sbfsem.image.Node(varargin{:});

			% Where the imported image is saved
			obj.filePath = filePath;

			if isempty(obj.imData)
				obj.imData = imread(obj.filePath);
			end

			% Use filename if other name isn't specified
			if isempty(obj.name)
				tmp = strsplit(obj.filePath, filesep);
				obj.name = tmp{end};
			end

            % Then remove filename from path
            obj.filePath(1:end-numel(obj.name)) = [];
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

		function ax = show(obj, ax)
			if nargin == 2
				validateattributes(ax, {'handle'}, {});
				fh = ax.Parent;
			else
				fh = figure();
				ax = axes('Parent', fh);
            end	
			imshow(obj.imData, 'Parent', fh.Children);
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
	end
end