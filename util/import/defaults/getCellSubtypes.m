function x = getCellSubtypes(cellType)
	% get the cell subtype
	%
	% INPUT: cellType 		string from CellTypes
	% OUTPUT: x 			cellstr of subtypes
	%
	% 19Jun2017 - SSP - created

	switch lower(cellType)
	case {'ganglion cell', 'gc'}
		x = {'unknown','midget', 'parasol', 'small bistratified',... 
		'large bistratified', 'smooth', 'melanopsin', 'broad throny'};
	case {'amacrine cell', 'ac'}
		x = {'unknown', 'wiry', 'semilunar',...
		'aii', 'a17', 'a1', 'a8', 'a3', 'a5'...
		'starburst', 'dopaminergic', 'on-off lateral'};
	case {'horizontal cell', 'hc'}
		x = {'unknown', 'h1', 'h2', 'axon1', 'axon2'};
	case {'bipolar cell', 'bc'}
		x = {'unknown', 'midget', 'blue', 'rod', 'giant',...
		'db1', 'db2', 'db3a', 'db3b', 'db4', 'db5', 'db6'};
	case {'photoreceptor', 'pr'}
		x = {'s', 'lm', 'rod', 'l', 'm'};
	case {'interplexiform cell', 'ipc'}
		x = {'unknown'};
	end
