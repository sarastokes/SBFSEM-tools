function x = CellSubtypes(cellType)
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
		'AII', 'A17', 'A1', 'A8', 'A3', 'A5'...
		'starburst', 'dopaminergic', 'on-off lateral'};
	case {'horizontal cell', 'hc'}
		x = {'unknown', 'h1', 'h2', 'h1 axon', 'h2 axon'};
	case {'bipolar cell', 'bc'}
		x = {'unknown', 'midget', 'blue', 'rod', 'giant',...
		'DB1', 'DB2', 'DB3a', 'DB3b', 'DB4', 'DB5', 'DB6'};
	case {'photoreceptor', 'pr'}
		x = {'cone', 'rod'};
	case {'interplexiform cell', 'ipc'}
		x = {'unknown'};
	end
