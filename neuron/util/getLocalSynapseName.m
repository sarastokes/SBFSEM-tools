function name = getLocalSynapseName(typeID, tag)
	% GETLOCALSYNAPSENAME
    %
    % 30Sept2017 - SSP

	if isempty(tag)
		tag = [];
    elseif isempty(cell2mat(tag))
        tag = [];
    else
        tag = char(tag);
	end

	switch typeID
		case 34
			if strcmp(tag, 'gaba')
				name = 'gaba fwd';
			else
				name = 'conv pre';
			end
		case 35
			if ~isempty(tag)
				switch tag
					case 'gaba'
						name = 'gaba fwd';
					case 'bipolar;ribbon;glutamate'
						name = 'ribbon post';
					case 'bipolar;conventional;glutamate';
						name = 'bip conv post';
					case 'conventional;ta'
						name = 'basal ta';
					case 'conventional;nta'
						name = 'basal nta';
					case 'conventional;mnta'
						name = 'basal mnta';
					otherwise
						name = 'conv post';
				end
			else
				name = 'conv post';
			end
		case 73
			name = 'ribbon';
		case [85, 181, 182]
			name = 'desmosome';
		case 189
			name = 'bc conv pre';
		case [240, 241]
			name = 'gaba fwd';
		otherwise
			T = getTypeIDs();
			row = cell2mat(T.ID) == typeID;
			name = T.Name(row,:);
			name = lower(name);
	end
