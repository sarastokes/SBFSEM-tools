function [im, map] = stack2gif(I, flipStack)
	% STACK2GIF Make a gif of images in stack
	% INPUTS: 	I 			ImageStack
	%			flipStack	[false] reverse list
	%
	% 2Oct2017 - SSP

	validateattributes(I, {'ImageStack'}, {});
	if nargin < 2 
		flipStack = false;
		node = I.head;
	else
		node = I.tail;
	end
	fpath = node.filePath;
	fpath(end-length(node.name):end) = []; 
	fpath = [fpath, filesep, 'EMstack.gif'];

	node.show();
	axis tight;
	set(gca, 'NextPlot', 'ReplaceChildren',...
		'Visible', 'off');
	f = getframe;
	[im, map] = rgb2ind(f.cdata, 256, 'nodither');
	im(1, 1, 1, I.numNodes) = 0;
	for i = 1:I.numNodes
		if flipStack
			node = node.previous;
		else
			node = node.next;
		end
		if isempty(node)
			return;
		end
		node.show(gca);
		f = getframe;
		im(:, :, 1, i) = rgb2ind(f.cdata, map, 'nodither');
	end
	imwrite(im, map, fpath,... 
		'DelayTime', 0.15,...
		'LoopCount', inf);


