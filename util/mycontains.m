function result = mycontains(str, pattern)
	% CONTAINS  For pre-2016 matlab
    try 
        result = contains(str, pattern);
    catch
        result = ~isempty(strfind(str, pattern)); %#ok<STREMP>
    end
end