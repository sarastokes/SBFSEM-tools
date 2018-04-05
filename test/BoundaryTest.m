classdef BoundaryTest < matlab.unittest.TestCase
    % BOUNDARYTEST
    %
    % Description:
    %   Tests for IPL boundary marker classes
    %
    % History:
    %   2Apr2018 - SSP
    % ---------------------------------------------------------------------
    properties
        fh
        ax
        INL
    end
    
    methods (TestClassSetup)
        function createBoundary(testCase)
            testCase.INL = sbfsem.builtin.INLBoundary('i');
            testCase.INL.update();
            
            testCase.fh = figure('Name', 'BoundaryTestFigure');
            testCase.ax = axes('Parent', testCase.fh);
        end
    end
    
    methods (TestClassTeardown)
        function closeFigure(testCase)
            close(testCase.fh);
        end
    end
    
    methods (Test)
        function testAnalysis(testCase)
            import matlab.unittest.constraints.HasSize;
            
            % Specify the number of xy points for grid
            testCase.INL.doAnalysis(200);
            testCase.verifyThat(...
                testCase.INL.newXPts, HasSize([1 200]),...
                'Incorrect xpts size');
            testCase.verifyThat(...
                testCase.INL.newYPts, HasSize([1 200]),...
                'Incorrect ypts size');
            testCase.verifyThat(...
                testCase.INL.interpolatedSurface, HasSize([200 200]),...
                'Incorrect interpolated surface size');           
        end
        
        function testXYEval(testCase)
            import matlab.unittest.constraints.HasElementCount;
            
            x = testCase.INL.xyEval(...
                median(testCase.INL.newXPts),median(testCase.INL.newYPts));
            testCase.verifyThat(...
                x, HasElementCount(1),...
                'Incorrect output size');
        end
        
        function testVisualize(testCase)
            import matlab.unittest.constraints.IsEmpty;
            import matlab.unittest.constraints.HasElementCount;
            
            % First without the data
            testCase.INL.plot('ax', testCase.ax);           
            testCase.verifyThat(...
                testCase.ax.Children, HasElementCount(1),...
                'Plot surface created >1 graphics object');
            
            % Ensure boundary surface is removed
            sbfsem.core.BoundaryMarker.deleteFromScene(testCase.ax);
            testCase.verifyThat(...
                testCase.ax.Children, IsEmpty,...
                'Graphics objects remaining after deleted surface');
            
            % Add the boundary surface and data
            testCase.INL.plot('ax', testCase.ax, 'showData', true);            
            testCase.verifyThat(...
                testCase.ax.Children, HasElementCount(2),...
                'Incorrect graphics object count from plot with data');
            
            % Ensure both boundary surface and data are removed
            sbfsem.core.BoundaryMarker.deleteFromScene(testCase.ax);
            testCase.verifyThat(...
                testCase.ax.Children, IsEmpty,...
                'Graphics objects remaining after deleted surf and data');
        end
    end
end