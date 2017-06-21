function azel = setAzimuth(azel, inc, whichDir)


	switch whichDir
	case 'up'
		azel(1,1) = azel(1,1) + inc;
	case 'down'
		azel(1,1) = azel(1,1) + inc;
	end