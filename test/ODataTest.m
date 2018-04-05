classdef ODataTest < matlab.unittest.TestCase
    
    methods
        function testInput(testCase)
            x = @()sbfsem.io.OData();
            testCase.verifyError(...
                x, 'SBFSEM:OData:InsufficentInput',...
                'OData constructor did not error for no input');
        end
    end
end