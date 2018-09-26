classdef NeuronOData < sbfsem.io.OData
% NEURONODATA
%
% Description:
%   Handles OData queries related to a single neuron ("Structure")
%
% Constructor
%   obj = NEURONODATA(ID, source);
%
% Inputs: 
%   ID      Viking ID number
%   Source  Volume name
%
% Properties:
%   ID              Viking ID number
% Inherited properties:
%   Source          Full volume name
% Private properties:
%   vikingData      Neuron structure data
%   nodeData        Annotation locations
%   edgeData        Connections between nodes
%
% Methods:
%   s = obj.getStructure()
%   t = obj.getNodes()
%   t = obj.getEdges()
%   [a,b,c] = pull();
% 
% Use:
%   % Create OData object (cell 127 from NeitzInferiorMonkey)
%   o127 = NeuronOData(127, 'i'); 
%
% History:
%   10Nov2017 - SSP
%   3Jan2017 - SSP - moved synapses to SynapseOData, removed volume scale
% -------------------------------------------------------------------------
    
    properties (SetAccess = private)
        ID
    end
    
    properties (Access = private)
        vikingData
        nodeData
        edgeData
    end
    
    methods
        function obj = NeuronOData(ID, source)
            % NEURONODATA  Serves as middleman b/w OData and Matlab
            %  
            % Inputs:
            %   ID          neuron structure ID (from Viking)
            %   source      volume name
            

            obj@sbfsem.io.OData(source);
            assert(isnumeric(ID), 'ID must be numeric');
            
            vikingData = readOData(getODataURL(ID, source, 'neuron'));            
            
            if ~ismember(vikingData.TypeID, [1, 3])
                error('SBFSEM:NeuronOData:invalidTypeID',...
                    'Structure ID was not valid');
            else
                obj.vikingData = vikingData;
                obj.ID = ID;
                obj.source = source;
            end
        end
        
        function viking = getStructure(obj)
            % GETSTRUCTURE  Returns neuron's viking data
            viking = obj.vikingData;
        end

        function nodes = getNodes(obj)
            % GETNODES  Returns nodes as table
            
            if isempty(obj.nodeData)
                obj.nodeData = obj.fetchLocationData(obj.ID);
            end

            nodes = array2table(obj.nodeData);
            nodes.Properties.VariableNames = obj.getNodeHeaders(); 
        end

        function edges = getEdges(obj)
            % GETEDGES  Returns edges as table

            if isempty(obj.edgeData)
                obj.edgeData = obj.fetchLinkData(obj.ID);
            end

            % If edgeData is still empty, single annotation structure
            if isempty(obj.edgeData)
                disp('No edges found');
                edges = [];
                return;
            else
                edges = array2table(obj.edgeData);
                edges.Properties.VariableNames = obj.getEdgeHeaders;
            end

        end
             
        function [viking, nodes, edges] = pull(obj)
            % PULL  Fetches all data (nodes, edges, child)
            
            obj.update();

            viking = obj.vikingData;
            nodes = obj.getNodes();
            edges = obj.getEdges();
        end
    end
    
    methods (Access = private)
        function update(obj)
            % UPDATE  Fetches all existing data
            
            obj.vikingData = readOData(getODataURL(obj.ID, obj.source, 'neuron')); 
            if ~isempty(obj.nodeData)
                obj.nodeData = [];
                obj.nodeData = obj.fetchLocationData(obj.ID);
            end

            if ~isempty(obj.edgeData)
                obj.edgeData = [];
                obj.edgeData = obj.fetchLinkData(obj.ID);
            end
        end
    end
end