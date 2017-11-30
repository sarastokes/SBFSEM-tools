function y = parseTags(x)
    % PARSETAGS  Get rid of the HTML markup and keep the synapse names
    %
    % 1Oct2017 - SSP
    if ischar(x)
        x = {x};
    end
    validateattributes(x, {'cellstr', 'cell'},{});

    y = cell(0,1);
    % localNames = cat(2, localNames, regexp(tag, '"\w*\w*"', 'match');
    
    for i = 1:size(x,1)
        if ~isempty(x{i}) && numel(x{i}) > 1 && ~strcmp(x{i}, '-')
            tag = x{i};
            str = [];      
            % tags are inside quotes
            ind = strfind(tag, '"');
            % each column is a beginning and ending quote
            ind = reshape(ind, 2, numel(ind)/2);
            for j = 1:numel(ind)/2
                % get the string inside each set of quotes
                str = [str, tag(ind(1,j)+1:ind(2,j)-1), ';']; %#ok<AGROW>
            end 
            % remove the last semicolon
            str = str(1:end-1);
        else
            str = cell(1,1);
        end
        y = cat(1, y, str);
    end