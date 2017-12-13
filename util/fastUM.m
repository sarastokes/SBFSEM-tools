function str = fastUM()
% FASTUM  Outputs micron symbol or copies to clipboard
% 12Dec2017 - SSP

        str = '?m';
        
        if nargout == 0
            clipboard('copy', str);
        end