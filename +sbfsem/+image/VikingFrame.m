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

	properties (Constant = true)
		PIX_PER_INCH = 95.9866;
	end

	methods (Static)
		function in = um2in(microns, source)
			% GETSCALEBAR
			if nargin < 2
				nm_per_pix = 7.5;
			else
				source = validateSource(source);
				volumeScale = getODataScale(source);
				% Assuming equal X and Y dimension scaling
				nm_per_pix = volumeScale(1);
			end
			um_per_pix = nm_per_pix/1e3;
			pix = microns / um_per_pix;
			in = pix / sbfsem.image.VikingFrame.PIX_PER_INCH;			
		end
	end
end