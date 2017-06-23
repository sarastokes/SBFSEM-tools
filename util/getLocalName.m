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
				localName = 'conv pre';
			case 'postsynapse'
				switch lower(synTag)
					case 'conventional'
						localName = 'conv post';
					case 'bipolar;glutamate;ribbon'
						localName = 'ribbon post';
					case 'bipolar;conventional;glutamate'
						localName = 'bip conv post';
				end % tag switch
			case {'plaque-like post', 'plaque-like pre'}
				localName = 'gaba fwd';
			case 'gap junction'
				localName = 'gap junction';
      case 'cell'
        localName = 'cell';
      case 'touch'
      	localName = 'touch';
      case {'cistern pre','cistern post'}
      	localName = 'denosome';
      case 'unknown'
        localName = 'unknown';
      otherwise
        fprintf('unrecognized synType = %s\n', lower(synType));
				localName = lower(synType);
		end % type switch