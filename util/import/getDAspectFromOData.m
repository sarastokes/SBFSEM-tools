function volumeScale = getDAspectFromOData(source)
	% GETDASPECTFROMODATA  Get scaled volume dimensions

	volumeScale = getODataScale(source);
	volumeScale = volumeScale/max(abs(volumeScale));