function cellStats(cellData, uniqueOnly)
	% print cell info to the cmd line, will be adding more soon
	% INPUT: 	
	%					cellData 		from parseCellData.m
	%	OPTIONAL:
	%					uniqueOnly	[true] set to false to return unique and total synapse structures
	%
	%
	% 10May2017 - SSP - created
	% 16Jun2017 - SSP - ready, added uniqueOnly

	if nargin < 2
		uniqueOnly = true;
	end

	if ~uniqueOnly
		fprintf('Total synapse structures:\n');
		for ii = 1:length(cellData.typeData.names)
			fprintf('%u %s\n',... 
				cellData.typeData.count(ii), cellData.typeData.names{ii});
		end
	end

	fprintf('Unique synapse structures:\n');
	for ii = 1:length(cellData.typeData.names)
		fprintf('%u %s\n',...
			cellData.typeData.uniqueCount(ii), cellData.typeData.names{ii});
	end