classdef SWC < handle
% SWC
%
% Description:
%	A class for handling SWC files
%
% Layout:
%       --> n T x y z R P <--
% n is an integer label that identifies the current point and increments by
% one from one line to the next.
%
% T is an integer representing the type of neuronal segment, such as soma,
% axon, apical dendrite, etc. The standard accepted integer values are
% given below.
%
% 0 = undefined 1 = soma 2 = axon 3 = dendrite 4 = apical dendrite 5 = fork
% point 6 = end point 7 = custom x, y, z gives the cartesian coordinates of
% each node.
%
% R is the radius at that node.
%
% P indicates the parent (the integer label) of the current point or -1 to
% indicate an origin (soma).
%
% Resources:
%	Above description from: www.research.mssm.edu/cnic/swc.html
%
% History:
%   12Mar2018 - SSP
%   16Apr2018 - SSP - finished
%	13May2018 - SSP - almost complete re-write
% ----------------------------------------------------------------------

	properties (SetAccess = private)
		T
		idMap
        hasSoma
        hasAxon
        fPath
    end

    properties (Access = private)
        neuron
        G
	end

	properties (Transient = true, Access = private)
		nodeCount
	end

	methods
		function obj = SWC(neuron, fPath, varargin)
			% Parse the inputs
			assert(isa(neuron, 'Neuron'), 'Input a Neuron object');
            obj.neuron = neuron;

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'hasSoma', true, @islogical);
            addParameter(ip, 'hasAxon', false, @islogical);
            addParameter(ip, 'fPath', cd, @isdir);
            parse(ip, varargin{:});
            obj.hasSoma = ip.Results.hasSoma;
            obj.hasAxon = ip.Results.hasAxon;
            
            if isempty(ip.Results.fPath)
                obj.fPath = uiputfile();
            else
            	assert(isdir(ip.Results.fPath), 'fPath must be a valid file path!');
                obj.fPath = ip.Results.fPath;
            end

            % Convert to a directed graph
            [G, obj.idMap] = graph(neuron, 'directed', true);
            assert(nnz(G.indegree == 2) == 0, 'Greater than 1 indegree!');
            % assert(numel(G.indegree) > 1, 'More than one starting node!');
            obj.G = G;
        end

        function go(obj)
            % GO  Create the SWC table

            obj.nodeCount = 0;

            % Identify the starting node
            startNode = find(obj.G.indegree == 0);

            % Create the SWC table
            obj.T = table(obj.idMap, NaN(size(obj.idMap)),...
                zeros(numel(obj.idMap), 3), zeros(size(obj.idMap)),...
                zeros(size(obj.idMap)));
            obj.T.Properties.VariableNames = {'ID', 'SWC', 'XYZ',...
                'Radius', 'Parent'};
            obj.T(startNode, :).Parent = -1;
            obj.T(startNode, :).SWC = 5;

            % Now recursively assign all SWC types
            obj.assignType(1);
            obj.assignAttributes();
        end
        
        function save(obj, fPath)
            if nargin == 2
                obj.fPath = fPath;
            end
            
            obj.initSWC();
        end
        
        function str = createEntry(obj, nodeNumber)
            % ADDENTRY
            row = obj.T(nodeNumber, :);
            
            str = sprintf('%u %u %.3f %.3f %.3f %.3f %d\n',...
                nodeNumber, row.SWC, row.XYZ, row.Radius, row.Parent);
        end
	end

	methods (Access = private)


		function assignType(obj, baseNode)
			% ASSIGNTYPE  Recursively assign dendrites to 3 types:
			%	3 = Dendrite, 5 = Fork point, 6 = End point

			childNodes = obj.G.successors(baseNode);
			if numel(childNodes) == 0
				fprintf('No child nodes for base node %u\n', baseNode);
				return
			end

			for i = 1:numel(childNodes)
				iNode = childNodes(i);
				obj.T(iNode, :).Parent = baseNode;

				switch numel(obj.G.successors(iNode))
					case 0 % End point
						obj.T(iNode, :).SWC = 6;
					case 1 % Dendrite
						obj.T(iNode, :).SWC = 3;
						obj.assignType(iNode);
					otherwise % Fork point
						obj.T(iNode, :).SWC = 5;
						obj.assignType(iNode);
				end
			end
		end

        function assignAttributes(obj)
            % ASSIGNATTRIBUTES

            for i = 1:height(obj.T)
                iID = obj.T(i, :).ID;
                x = obj.neuron.nodes(find(obj.neuron.nodes.ID == iID), :);
                obj.T(i, :).Radius = x.Rum;
                obj.T(i, :).XYZ = x.XYZum;
            end
        end
	end

	methods (Static)
		function obj = initSWC(obj)
			% INITSWC  Creates the headers for an SWC file

            fid = fopen([obj.fPath, filesep, '.swc']);
			fwrite(fid, ['# ORIGINAL_SOURCE sbfsem tools', newline], 'char');
			fprintf(fid, '# CREATURE %s\n', getAnimal(obj.neuron.source));
			fprintf(fid, '# REGION');
			switch obj.neuron.source
				case 'NeitzTemporalMonkey'
					fprintf(fid, ' Temporal\n');
				case 'NeitzInferiorMonkey'
					fprintf(fid, ' Inferior\n');
				otherwise
					fprintf(fid, '\n');
			end
			fprintf(fid, '# FIELD/LAYER\n# TYPE\n# CONTRIBUTOR\n');
			fprintf(fid, '# REFERENCE\n# RAW\n# EXTRAS\n');
			fprintf(fid, '# SOMA_AREA %.3f\n', pi*obj.neuron.getSomaSize^2);
			fprintf(fid, '# SHRINKAGE_CORRECTION 1.0 1.0 1.0\n');
			fprintf(fid, '# VERSION_NUMBER 1.0\n');
			fprintf(fid, '# VERSION_DATE 2017-03-12\n');
			fprintf(fid, '# SCALE %.4f %.4f %.4f',...
				volumeScale/max(volumeScale));
			fprintf(fid, '\n');
            fclose(fid);
		end
	end
end
