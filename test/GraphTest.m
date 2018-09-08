classdef GraphTest < matlab.unittest.TestCase
% GRAPHTEST
%
% Description:
%   Test for methods relying on graph representation of neuron morphology.
%
% History:
%   30May2018 - SSP
% -------------------------------------------------------------------------
    properties
        neuron
        segments
        segmentTable
        nodeIDs
        startNode
        SWC
    end

    methods (TestClassSetup)
        function createNeuron(testCase)
            testCase.neuron = Neuron(943, 'i');
            % Segment neuron dendrites
            [testCase.segments, testCase.segmentTable, testCase.nodeIDs,...
                testCase.startNode] = dendriteSegmentation(testCase.neuron);
            % Create base SWC conversion
            testCase.SWC = sbfsem.io.SWC(testCase.neuron, 'startNode', 186);
            testCase.SWC.go();
        end
    end

    methods (Test)
        function testGraph(testCase)
            G = testCase.neuron.graph('directed', true);
            testCase.assertClass(G,  'digraph',...
                'Output was not class digraph');
            G = testCase.neuron.graph('directed', false);
            testCase.assertClass(G, 'graph',...
                'Output was not class graph');
        end

        function testNodeIDs(testCase)
            [~, IDs] = testCase.neuron.graph('directed', true);
            testCase.verifyEqual(...
                testCase.nodeIDs, IDs,...
                'NodeID indexing mismatch');
        end
        
        function testSWC(testCase)
            G = testCase.neuron.graph('directed', false);
            testCase.verifyEqual(...
                find(G.degree == 1),...
                find(testCase.SWC.T.ID == 6),...
                'Incorrect IDs for terminal nodes'); %#ok<*FNDSB>
        end
    end
end
