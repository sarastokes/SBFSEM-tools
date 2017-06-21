function x = CellTypes(abbrevFlag)
	% Possible cell types
	%
	% INPUTS: abbrevFlag 	any input will return short names
	% OUTPUT: x				cellstr of cell types
	%
	% 19Jun2017 - SSP - created

	if nargin < 1
		% no abbreviations
		x = {'unknown',... 
			'ganglion cell',... 
			'bipolar cell',... 
			'horizontal cell',... 
			'amacrine cell',...
			'photoreceptor',...
			'interplexiform cell'};
	else
		x = {'--', 'GC', 'BC', 'HC', 'AC','PR', 'IPC'};
	end
