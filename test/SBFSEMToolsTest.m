function result = SBFSEMToolsTest()
    % SBFSEMToolsTest
    % 
    % Description:
    %   Runs all tests in folder
    %
    % Output:
    %   result      Test results
    % ---------------------------------------------------------------------
    
    import matlab.unittest.TestSuite
    
    suiteFolder = TestSuite.fromFolder(fileparts(mfilename('fullpath')));
    result = run(suiteFolder);