function localName = getLocalName(synType, synTag)
	% gets the specific synapse name used by SBSFEM tools
	%
	% 10May2017 - SSP - created


	if isempty(synTag)
		switch synType
		case 'Ribbon Synapse'
			localName = 'ribbon pre';
		case 'BC Conventional Synapse'
			localName = 'bip conv pre';
		case 'Conventional'
			localName = 'conv pre';
		case 'Postsynapse'
			switch synTag
			case 'Conventional'
				localName = 'conv post';
			case 'Bipolar;Glutamate;Ribbon'
				localName = 'ribbon post';
			case 'Bipolar;Conventional;Glutamate'
				localName = 'bip conv post';
			end % tag switch
		otherwise
			localName = lower(synType);
		end
	end