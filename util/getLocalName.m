function localName = getLocalName(synType, synTag)
	% gets the specific synapse name used by SBSFEM tools
	%
	% 10May2017 - SSP - created
	% 6Jun2017 - SSP - added more types
	% 16Jun2017 - SSP - ready

	switch lower(synType)
		case 'ribbon synapse'
			localName = 'ribbon pre';
		case 'bc conventional synapse'
			localName = 'bip conv pre';
		case 'conventional'
			switch lower(synTag)
			case 'gaba'
				localName = 'gaba fwd';
			otherwise
				localName = 'conv pre';
			end
		case 'postsynapse'
			switch lower(synTag)
				case 'conventional'
					localName = 'conv post';
				case 'bipolar;glutamate;ribbon'
					localName = 'ribbon post';
				case 'bipolar;conventional;glutamate'
					localName = 'bip conv post';
				case 'conventional;gaba'
					localName = 'gaba fwd';
				case 'ta'
					localName = 'triad basal';
				case 'nta'
					localName = 'nontriad basal';
				case 'mnta'
					localName = 'marginal basal';
				otherwise
					localName = 'postsynapse';
			end % tag switch
		case {'plaque-like post', 'plaque-like pre'}
			localName = 'gaba fwd';
		case 'gap junction'
			localName = 'gap junction';
		case 'touch'
			switch lower(synTag)
			case 'ta'
				localName = 'triad basal';
			case 'nta'
				localName = 'nontriad basal';
			case 'mnta'
				localName = 'marginal basal';
			otherwise
				localName = 'touch';
			end
		case {'cistern pre','cistern post', 'adherens'}
			localName = 'desmosome';
		case 'endocytosis'
			localName = 'endocytosis';
		case 'unknown'
			localName = 'unknown';
		case 'cell'
			localName = 'cell';
		otherwise
			fprintf('unrecognized synType = %s\n', lower(synType));
				localName = lower(synType);
	end % type switch