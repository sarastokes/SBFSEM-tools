function result = contains(str, pattern)
	% CONTAINS  For pre-2016 matlab
    result = ~isempty(strfind(str, pattern)) ;
end