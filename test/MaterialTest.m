classdef MaterialTest < matlab.unittest.TestCase
% MATERIALTEST
%
% History:
%   30Mar2018 - SSP
%   30May2018 - SSP - fixed setup, teardown of figure
% -------------------------------------------------------------------------

	properties
		ax 	% Axes handle
		s  	% Surface handle
		p 	% Patch handle
	end

	methods (TestClassSetup)
		function createFigure(testCase)
			fh = figure('Name', 'TestFigure');
			testCase.ax = axes(fh);
			hold(testCase.ax, 'on');

			% Create patch and surface render objects
			[x, y, z] = cylinder(2);
			testCase.s = surf(x, y, z, 'Parent', testCase.ax);
			testCase.p = patch('Parent', testCase.ax,...
				'XData', x(2,:)+3, 'YData', y(2,:)+3, 'ZData', z(2,:));
		end
    end
    
    methods (TestClassTeardown)
        function closeFigure(testCase)
            close(testCase.ax.Parent);
        end
    end

	methods (Test)
		function testSet(testCase)
			M = sbfsem.render.Material(testCase.s);

			M.set('FaceColor', 'b');
			testCase.verifyEqual(...
				testCase.s.FaceColor, [0 0 1],...
				'Set did not change surface face color');
		end
	end
end