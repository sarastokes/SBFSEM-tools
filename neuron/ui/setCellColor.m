function x = setCellColor(hexColor, str)
	% fill uitable cell with text and bkgd color
	% INPUTS:
	%			rgbColor		cell background color [1 1 1]
	%			txt 				cell text
	%	OUTPUT: html formatted uitable data
	%
	% 21Jun2017 - SSP - moved from static methods

	x = ['<html><table border=0 width=200 bgcolor=',... 
		hexColor, '><TR><TD>', str, '</TD></TR> </table></html>'];


