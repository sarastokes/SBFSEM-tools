classdef SWC < handle
% SWC
%
% Description:
%	A class for handling SWC files
%
% Example:
%   c4568 = Neuron(4568, 'i');
%   x = sbfsem.io.SWC(c4568);
%   x.save();
%
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
% 0 = undefined, 1 = soma, 2 = axon, 3 = dendrite, 4 = apical dendrite, 
% 5 = fork, point 6 = end point 7 = custom x, y, z gives the cartesian  
% coordinates of each node.
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
%   1Jun2018 - SSP - new algorithm
%   9Jun2018 - SSP - Segment class, now node ID is always < parent ID
% -------------------------------------------------------------------------

	properties (SetAccess = public)
		ID
        T
        hasAxon
        Segmentation
    end

    properties (Access = private)
        fPath
        fName
    end

    properties (Transient = true, Access = private)
        neuron
    end

    properties (Dependent = true, Hidden = true)
        startNode
        segments
        idMap
        swcMap
        G
    end

	methods
		function obj = SWC(neuron, varargin)
			% Parse the inputs
			assert(isa(neuron, 'Neuron'), 'Input a Neuron object');
            obj.neuron = neuron;
            obj.ID = neuron.ID;

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'hasAxon', false, @islogical);
            addParameter(ip, 'fPath', [], @isdir);
            addParameter(ip, 'startNode', [], @isnumeric);
            parse(ip, varargin{:});
            obj.hasAxon = ip.Results.hasAxon;
            obj.fPath = ip.Results.fPath;
            if isempty(ip.Results.startNode)
                startNode = minmaxNodes(obj.neuron, 'min');
            else
                startNode = ip.Results.startNode;
            end

            obj.fName = ['c', num2str(obj.neuron.ID), '.swc'];

            % Perform graph segmentation
            obj.Segmentation = sbfsem.render.Segment(neuron, startNode);
            
            % Setup the SWC information
            obj.go();
        end

        function startNode = get.startNode(obj)
            if ~isempty(obj.Segmentation)
                startNode = obj.Segmentation.startNode;
            end
        end

        function segments = get.segments(obj)
            if ~isempty(obj.Segmentation)
                segments = obj.Segmentation.segments;
            end
        end

        function idMap = get.idMap(obj)
            if ~isempty(obj.Segmentation)
                idMap = obj.Segmentation.nodeIDs;
            end
        end

        function swcMap = get.swcMap(obj)
            if ~isempty(obj.Segmentation)
                swcMap = obj.Segmentation.discoverIDs;
            end
        end

        function G = get.G(obj)
            if ~isempty(obj.Segmentation)
                G = obj.Segmentation.Graph;
            end
        end

        function go(obj)
            % GO  Create the SWC table
            disp('Creating SWC node table...');

            % Create the SWC table
            obj.T = table(obj.idMap, NaN(size(obj.idMap)),...
                zeros(numel(obj.idMap), 3), zeros(size(obj.idMap)),...
                zeros(size(obj.idMap)), zeros(size(obj.idMap)),...
                zeros(size(obj.idMap)));
            obj.T.Properties.VariableNames = {'ID', 'SWC', 'XYZ',...
                'Radius', 'Parent', 'SWCID', 'SWCParent'};
            obj.T(obj.startNode, :).Parent = -1;
            obj.T(obj.startNode, :).SWCParent = -1;
            switch numel(neighbors(obj.G, obj.startNode))
                case 1
                    obj.T(obj.startNode, :).SWC = 6;
                case 2
                    obj.T(obj.startNode, :).SWC = 3;
                otherwise
                    obj.T(obj.startNode, :).SWC = 5;
            end
            obj.T(obj.startNode, :).SWCID = obj.node2swc(obj.startNode);

            for i = 1:numel(obj.segments)
                obj.segmentTyping(obj.segments{i});
            end

            if ~isempty(isnan(obj.T.SWC))
                disp(obj.T.ID(isnan(obj.T.SWC)));
            end
            obj.assignAttributes();

            obj.T = sortrows(obj.T, 'SWCID');
        end

        function save(obj, fPath)
            % SAVE  Save SWC table as .swc file
            if nargin == 2
                assert(isdir(fPath), 'fPath must be a valid file path!')
                obj.fPath = fPath;
            end

            if isempty(obj.fPath)
                obj.fPath = uigetdir();
            end

            if isempty(obj.T)
                obj.go();
            end

            obj.writeSWC();
        end
	end

	methods (Access = private)

        function swcID = node2swc(obj, nodeID)
            swcID = find(obj.swcMap == nodeID);
        end

        function segmentTyping(obj, segment)
            % SEGMENTTYPING

            for i = 1:numel(segment)-1
                node = segment(i);
                obj.T(node, :).SWCID = obj.node2swc(node);
                obj.T(node, :).Parent = segment(i+1);
                obj.T(node, :).SWCParent = obj.node2swc(segment(i+1));
                switch numel(neighbors(obj.G, node))
                    case 1
                        obj.T(node, :).SWC = 6;
                    case 2
                        obj.T(node, :).SWC = 3;
                    otherwise
                        obj.T(node, :).SWC = 5;
                end
            end
        end

        function assignAttributes(obj)
            % ASSIGNATTRIBUTES

            soma_id = obj.neuron.getSomaID();

            for i = 1:height(obj.T)
                iID = obj.T(i, :).ID;
                if isequal(iID, soma_id)
                    obj.T(i, :).SWC = 1;
                end
                x = obj.neuron.nodes(obj.neuron.nodes.ID == iID, :);
                obj.T(i, :).Radius = x.Rum;
                obj.T(i, :).XYZ = x.XYZum;
            end

        end

		function obj = writeSWC(obj)
			% WRITESWC  Creates the headers for an SWC file

            fid = fopen([obj.fPath, filesep, obj.fName], 'w');
            % Write the metadata
			fprintf(fid, '# ORIGINAL_SOURCE sbfsem tools\n');
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
			fprintf(fid, '# VERSION_DATE %s\n', datestr(now, 'YYYY-mm-DD'));
			fprintf(fid, '# SCALE 1.0 1.0 1.0\n');
			fprintf(fid, '\n');

            % Write the data
            for i = 1:height(obj.T)
                row = obj.T(i, :);
                fprintf(fid, '%u %u %.4f %.4f %.2f %.4f %d\n',...
                    row.SWCID, row.SWC, row.XYZ, row.Radius, row.SWCParent);
            end
            fclose(fid);

            disp(['Saved as ', obj.fPath, filesep, obj.fName]);
		end
	end
end
