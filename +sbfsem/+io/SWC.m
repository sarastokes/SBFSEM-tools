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
%   1Jun2018 - SSP - new algorithm
% ----------------------------------------------------------------------

	properties (SetAccess = private)
		T
        hasSoma
        hasAxon
        startNode
        segments
        idMap
    end
    
    properties (Access = private)
        fPath
        fName
    end
    
    properties (Transient = true, Access = private)
        neuron
        G
    end
    
	methods
		function obj = SWC(neuron, varargin)
			% Parse the inputs
			assert(isa(neuron, 'Neuron'), 'Input a Neuron object');
            obj.neuron = neuron;

            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'hasSoma', true, @islogical);
            addParameter(ip, 'hasAxon', false, @islogical);
            addParameter(ip, 'fPath', [], @isdir);
            addParameter(ip, 'startNode', 1, @isnumeric);
            parse(ip, varargin{:});
            obj.hasSoma = ip.Results.hasSoma;
            obj.hasAxon = ip.Results.hasAxon;
            obj.fPath = ip.Results.fPath;
            obj.startNode = ip.Results.startNode;

            obj.fName = ['c', num2str(obj.neuron.ID), '.swc'];

            % Convert to a directed graph
            [obj.G, obj.idMap] = graph(obj.neuron);
            [obj.segments, ~, ~, obj.startNode] = dendriteSegmentation(...
                obj.neuron, 'startNode', obj.startNode);
            
            obj.go();
        end

        function go(obj)
            % GO  Create the SWC table            
            disp('Creating SWC node table...');
            
            % Create the SWC table
            obj.T = table(obj.idMap, NaN(size(obj.idMap)),...
                zeros(numel(obj.idMap), 3), zeros(size(obj.idMap)),...
                zeros(size(obj.idMap)));
            obj.T.Properties.VariableNames = {'ID', 'SWC', 'XYZ',...
                'Radius', 'Parent'};
            obj.T(obj.startNode, :).Parent = -1;
            obj.T(obj.startNode, :).SWC = 5;

            for i = 1:numel(obj.segments)
                obj.segmentTyping(obj.segments{i});
            end
            
            if ~isempty(isnan(obj.T.SWC))
                disp(obj.T.ID(isnan(obj.T.SWC)));
            end
            obj.assignAttributes();
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

        function segmentTyping(obj, segment)
            % SEGMENTTYPING
            
            for i = 1:numel(segment)-1
                node = segment(i);
                obj.T(node, :).Parent = segment(i+1);
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

            for i = 1:height(obj.T)
                iID = obj.T(i, :).ID;
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
                case 'NeitzNasalMonkey'
                    fprintf(fid, ' Nasal\n');
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
                    i, row.SWC, row.XYZ, row.Radius, row.Parent);
            end
            fclose(fid);
            
            disp(['Saved as ', obj.fPath, filesep, obj.fName]);
		end
	end
end