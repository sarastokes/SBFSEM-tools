classdef NotYetImplemented < MException
% NOTYETIMPLEMENTED
%
% Description:
% 	A Matlab class similar to Python's NotImplementedError
%	Used for future code or for parent classes that require subclasses to
%	override the method.
%
% History:
%	7Mar2019 - SSP
% -------------------------------------------------------------------------

	methods
		function obj = NotYetImplemented(methodName, msg)
			if nargin < 2
				msg = '';
			end
			obj@MException('SBFSEM:NotYetImplemented',... 
                [methodName, '   ', msg]);
		end
	end
end