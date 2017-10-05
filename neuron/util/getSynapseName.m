function name = getSynapseName(typeID)
	% GETSYNAPSENAME  Returns the name associated with a typeID
	%
	% 30Sept2017 - SSP

	T = getTypeIDs();
	row = T.ID == typeID;
	name = T.Name(row,:);