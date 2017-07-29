function xyr =  getSomaXYR(Neuron)
    % get soma node for plot with viscircles
    % INPUT: Neuron
    % OUTPUT: xyr           [x, y, radius] (in microns)
    %
    % 29Jul2017 - SSP - created

	% find the row matching soma node uuid
	row = strcmp(Neuron.dataTable.UUID, Neuron.somaNode);
	% get the XYZ values		
    xyz = table2array(Neuron.dataTable(row, 'XYZum'));
    xyr = [xyz(1:2), Neuron.dataTable{row, 'Size'}];
    
    % diameter to radius
    xyr(3) = xyr(3)/2;
    
    % convert radius to microns
    if strcmp(Neuron.cellData.source, 'rc1')
		% 2.18nm per pixel
		xyr(3) = 2.18 .* xyr(3);
	else
		% 5nm per pixel
		xyr(3) = 5 .* xyr(3); % nm
    end
    xyr(3) = xyr(3) ./ 1000;