function azel = setElevation(azel, inc, whichDir)


	switch whichDir
	case 'up'
		azel(1,2) = azel(1,2) + inc;
	case 'down'
		azel(1,2) = azel(1,2) + inc;
	end