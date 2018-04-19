classdef VikingFrame < handle
% VIKINGFRAME
%
% Use:
%	Place an exported frame in Illustrator. The export parameters in the
%	notes below mean the image will be placed as 26.0453 inches square.
%	Create a scale bar by creating a line with the following size:
%
%		ScaleBarInches = sbfsem.images.VikingFrame(ScaleBarMicrons)
%
%	This must be done before scaling the image. All subsequent scaling
%	should be applied to both the scale bar line and the image. This is
%	easiest if the two are grouped (Ctrl+G) together.
%
% Notes:
%	Work in progress. For now, assumes you exported the frame at 2500 by
%	2500 pixels with 1 downsample.
%
% History:
%	7Mar2018 - SSP
% ----------------------------------------------------------------------

    properties (Access = private)
        nm_per_pix
    end
    
	properties (Constant = true)
		PIX_PER_INCH = 0.0104; % 95.9866;
    end
    
    methods
        function obj = VikingFrame(source)
            % VIKINGFRAME  Constructor
            if nargin == 0
                obj.nm_per_pix = 7.5;
            else
                source = validateSource(source);
                volumeScale = getODataScale(source);
                obj.nm_per_pix = volumeScale(1);
            end
        end
        
		function in = um2in(obj, microns, imPix, imInch)
			% GETSCALEBAR
            % 
            % Input:
            %   microns
            % Optional input:
            %   imPix       Pixels on height/width of exported image 
            %               Default = 2500
            %   imInch      Inches on height/width when placed into Adobe
            %               Illustrator. Default = 26.0453.
	
            % Convert from nm/pix to um/pix
			um_per_pix = obj.nm_per_pix/1e3;
            % Get the scale bar size in pixels
			pix = microns / um_per_pix;
            
            if nargin < 3
                pix2in = obj.PIX_PER_INCH;
                disp('VikingFrame - assuming 2500 pixels and 26.0453 in')
            else
                pix2in = imInch/imPix;
            end
			in = pix * pix2in;
		end
	end
end