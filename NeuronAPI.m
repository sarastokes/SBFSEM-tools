classdef (Abstract) NeuronAPI < handle

	properties (SetAccess = protected, GetAccess = public)
        % Cell ID in Viking
        ID
        % Volume cell exists in
        source
        % Neuron's data from Viking
        viking
        % Table of each location ID
        nodes
        % Table of the links between annotations
        edges
        % Volume dimensions (nm per pixel)
        volumeScale
        % Attributes of each synapse
        synapses
        % Closed curve geometries
        geometries
        % Date info pulled from odata
        lastModified
        % Analyses related to the neuron
        analysis = containers.Map();
        % Render of neuron
        model = [];
        % Omitted location IDs
        omittedIDs = [];
        % Transform applied	
        transform = [];
	end

	properties (Dependent = true, Transient = true, Hidden = true)
 		somaRow 	% Largest "cell" annotation in node's row
        offEdges    % Unfinished branches
        terminals   % Branch endings
 	end

	% methods (Abstract)
	% 	checkSynapses(obj)			% Any synapses/child structures?
	% 	checkGeometries(obj) 		% Any polygon annotations?
	% end

	methods
		function obj = NeuronAPI()
			% Maybe add link to Neuron factory later
		end

        function xyz = id2xyz(obj, IDs)
            row = ismember(obj.nodes.ID, IDs);
            xyz = obj.nodes{row, 'XYZum'};
        end
    end

    % Cell annotation methods
    methods
    	function offEdges = get.offEdges(obj)
    		if ismember('OffEdge', obj.nodes.Properties.VariableNames)
    			rows = obj.nodes.OffEdge == 1;
    			offEdges = obj.nodes(rows, :).ID;
    		else
    			offEdges = [];
    		end
    	end 

    	function terminals = get.terminals(obj)
    		if ismember('Terminal', obj.nodes.Properties.VariableNames)
    			rows = obj.nodes.Terminal == 1;
    			terminals = obj.nodes(rows, :).ID;
    		else
    			terminals = [];
    		end
    	end

        function xyz = getCellXYZ(obj, useMicrons)
            % GETCELLXYZ  Returns cell body coordinates
            %
            %   Inputs:     useMicrons  [t]  units = microns or volume
            % ----------------------------------------------------------
            if nargin < 2
                useMicrons = true;
            end

            row = obj.nodes.ParentID == obj.ID;
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y','Z'}};
            end
        end

        function cellNodes = getCellNodes(obj)
            % GETCELLNODES  Return only cell body nodes

            row = obj.nodes.ParentID == obj.ID;
            cellNodes = obj.nodes(row, :);
        end
 	end

    % Soma methods
    methods
    	function checkSynapses(obj)
    		% Should be specified by subclasses
    	end

    	function checkGeometries(obj)
    		% Should be specified by subclasses
    	end
    	
        function somaRow = get.somaRow(obj)
            % This is the row associated with the largest annotation
            somaRow = find(obj.nodes.Radius == max(obj.nodes.Radius));
        end

        function id = getSomaID(obj, toClipboard)
            % GETSOMAID  Get location ID for current "soma" node
            %
            % Optional input:
            %   toClipboard     Copy to clipboard (default = false)
            % ----------------------------------------------------------

            if nargin < 2
                toClipboard = false;
            end

            id = obj.nodes{obj.somaRow, 'ID'};
            % In case more than one node has maximum size
            id = id(1);

            if toClipboard
                clipboard('copy', id);
            end
        end

        function um = getSomaSize(obj, useDiameter)
            % GETSOMASIZE  Returns soma radius in microns
            %
            % Optional inputs:
            %   useDiameter   Return diameter not radius (false)
            % ----------------------------------------------------------
            if nargin < 2
                useDiameter = false;
                disp('Returning radius');
            end

            if useDiameter
                um = max(obj.nodes.Rum) * 2;
                if nargout == 0
                    fprintf('c%u soma diameter = %.3f um\n', obj.ID, um);
                end
            else
                um = max(obj.nodes.Rum);
                if nargout == 0
                    fprintf('c%u soma radius = %.3f um\n', obj.ID, um);
                end
            end
        end

        function xyz = getSomaXYZ(obj, useMicrons)
            % GETSOMAXYZ  Coordinates of soma
            %
            % Optional input:
            %   useMicrons      logical, default = true
            % ----------------------------------------------------------

            if nargin < 2 % default unit is microns
                useMicrons = true;
            end

            % get the XYZ values
            if useMicrons
                xyz = obj.nodes{obj.somaRow, 'XYZum'};
            else
                xyz = obj.nodes{obj.somaRow, {'X', 'Y', 'Z'}};
            end

            if size(xyz, 1) > 1
                xyz = xyz(1,:);
            end
        end
    end

    % Fuctions regarding synapses and other child structures
    methods 
        function IDs = synapseIDs(obj, whichSyn)
            % SYNAPSEIDS  Return parent IDs for synapses
            %
            % Input:
            %   whichSyn        synapse name (default = all)
            % -------------------------------------------------------------

            obj.checkSynapses();

            if nargin < 2
                IDs = obj.synapses.ID;
            else % Return a single synapse type
                if ischar(whichSyn)
                    whichSyn = sbfsem.core.StructureTypes(whichSyn);
                end
                row = obj.synapses.LocalName == whichSyn;
                IDs = obj.synapses(row,:).ID;
            end
        end

        function n = getSynapseN(obj, synapseName)
            % GETSYNAPSEN
            % Input:
            %   synapseName     Name of synapse to count
            % ----------------------------------------------------------
            obj.checkSynapses();
            if ischar(synapseName)
                synapseName = sbfsem.core.StructureTypes(synapseName);
            end
            n = nnz(obj.synapses.LocalName == synapseName);
        end

        function xyz = getSynapseXYZ(obj, syn, useMicrons)
            % GETSYNAPSEXYZ  Get xyz of synapse type
            %
            % Inputs:
            %   syn             Synapse name
            %   useMicrons      Logical (default = true)
            % -------------------------------------------------------------
            if nargin < 3
                useMicrons = true;
            end
            obj.checkSynapses();

            % Find synapse structures matching synapse name
            if ischar(syn)
                syn = sbfsem.core.StructureTypes(syn);
            end

            row = obj.synapses.LocalName == syn;
            IDs = obj.synapses.ID(row,:);
            % Find the unique instances of each synapse ID
            row = ismember(obj.nodes.ParentID, IDs) & obj.nodes.Unique;

            % Get the xyz values for only those rows
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y', 'Z'}};
            end
        end

        function synapseNames = synapseNames(obj, toChar)
            % SYNAPSENAMES  Returns a list of synapse types
            %
            % Input:
            %   toChar          Convert to char (default = false)
            %
            % Output:
            %   synapseNames    Array of sbfsem.core.StructureTypes
            %                   Or cell of strings, if toChar = true
            % -------------------------------------------------------------

            if nargin < 2
                toChar = false;
            end

            obj.checkSynapses();

            synapseNames = unique(obj.synapses.LocalName);
            if toChar
                synapseNames = vertcat(arrayfun(@(x) char(x),...
                    synapseNames, 'UniformOutput', false));
            end
        end


        function synapseNodes = getSynapseNodes(obj, onlyUnique)
            % GETSYNAPSENODES  Returns a table of only synapse annotations
            % Inputs:
            %   onlyUnique      t/f  return only unique locations
            % -------------------------------------------------------------
            obj.checkSynapses();
            if nargin < 2
                onlyUnique = true;
            end
            if onlyUnique
                row = obj.nodes.ParentID ~= obj.ID & obj.nodes.Unique;
            else
                row = obj.nodes.ParentID ~= obj.ID;
            end
            synapseNodes = obj.nodes(row, :);

            % Sort by parentID
            synapseNodes = sortrows(synapseNodes, 'ParentID');
        end

        function printSyn(obj)
            % PRINTSYN  Print synapse summary to the command line

            obj.checkSynapses();
            % Viking synapse names first
            [a, b] = findgroups(obj.synapses.TypeID);
            b2 = sbfsem.core.VikingStructureTypes(b);
            x = splitapply(@numel, obj.synapses.TypeID, a);
            fprintf('\n-------------------\nc%u synapses:', obj.ID);
            fprintf('\n-------------------\nViking synapse names:\n');
            for ii = 1:numel(x)
                fprintf('%u %s\n', x(ii), b2(ii));
            end
            % Then detailed SBFSEM-tools names
            fprintf('\n-------------------\nDetailed names:\n');
            synapseNames = obj.synapseNames;
            for i = 1:numel(synapseNames)
                fprintf('%u %s\n',...
                    size(obj.getSynapseXYZ(synapseNames(i)), 1),...
                    char(synapseNames(i)));
            end
            fprintf('\n-------------------\n');
        end
	end

	% Graph theory methods
	methods
        function [G, nodeIDs] = graph(obj, varargin)
            % NEURON2GRAPH  Create a graph representation
            %
            % Optional key/value inputs:
            %   directed        [f]     directed or undirected
            %   synapses        [f]     include child structures
            %   visualize       [f]     plot the graph?
            %
            % Outputs:
            %   G               graph or digraph
            %   nodesIDs        array (ith entry is loc ID of node i)
            % -------------------------------------------------------------

            ip = inputParser();
            addParameter(ip, 'directed', false, @islogical);
            addParameter(ip, 'synapses', false, @islogical);
            addParameter(ip, 'visualize', false, @islogical);
            parse(ip, varargin{:});

            if ip.Results.synapses
                edge_rows = obj.edges;
            else
                edge_rows = obj.edges.ID == obj.ID;
            end

            if ip.Results.directed
                G = digraph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(deblank(num2str(obj.edges.B(edge_rows,:)))));
            else
                G = graph(cellstr(num2str(obj.edges.A(edge_rows,:))),...
                    cellstr(num2str(obj.edges.B(edge_rows,:))));
            end

            if ip.Results.visualize
                figure();
                plot(G);
            end

            % Lookup table for locationIDs of nodes where ith entry is
            % the location ID of node i.
            nodeIDs = str2double(G.Nodes{:,:});

            % Remove any omitted nodes from the graph
            if ~isempty(obj.omittedIDs)
                for i = 1:numel(obj.omittedIDs)
                    G = G.rmnode(find(nodeIDs == obj.omittedIDs(i))); %#ok
                    nodeIDs = str2double(G.Nodes{:,:});
                end
                fprintf('Omitted %u locations\n', numel(obj.omittedIDs));
            end
        end
	end

	% RENDERING METHODS
	methods
        function model = build(obj, renderType, varargin)
            % BUILD  Quick access to render methods
            %
            % Inputs:
            %   renderType      'cylinder' (default), 'closedcurve', 'disc'
            %   varargin        Input to render function
            % Output:
            %   model           render object (also stored in properties)
            %--------------------------------------------------------------
            if nargin < 2
                renderType = 'cylinder';
            end

            if ~isempty(obj.model)
                obj.model = [];
            end

            switch lower(renderType)
                case {'cylinder', 'cyl'}
                    model = sbfsem.render.Cylinder(obj, varargin{:});
                case {'closedcurve', 'cc', 'curve'}
                    model = renderClosedCurve(obj, varargin{:});
                case {'outline'}
                    model = sbfsem.builtin.ClosedCurve(obj);
                case 'disc'
                    model = sbfsem.render.Disc(obj, varargin{:});
                otherwise
                    warning('Render type %s not found', renderType);
                    return;
            end
            obj.model = model;
        end

        function dae(obj, fName)
            % DAE  Export model as COLLADA file
            %
            % Inputs:
            %   fName       filename (char)
            %
            % See also:
            %   EXPORTSCENEDAE
            % -------------------------------------------------------------
            if isempty(obj.model)
                obj.build();
            elseif isnumeric(obj.model) || isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                warning('Model must be a Cylinder render, use exportSceneDAE');
                return;
            end

            if nargin < 2
                obj.model.dae();
            else
                obj.model.dae(fName);
            end
        end

        function render(obj, varargin)
            % RENDER
            %
            % Inputs:
            %   varargin        See render function inputs
            %
            % See also:
            %   RENDERCLOSEDCURVE, SBFSEM.RENDER.CYLINDER
            % -------------------------------------------------------------

            if ~isempty(obj.model)
                if isa(obj.model, 'sbfsem.builtin.ClosedCurve')
                    obj.model.trace(varargin{:});
                elseif isnumeric(obj.model) % Closed curve volume
                    volumeRender(obj.model,...
                        'Tag', ['c', num2str(obj.ID)],...
                        varargin{:});
                else
                    obj.model.render(varargin{:});
                    view(3);
                end
            else
                warning('No model - use BUILD function first');
            end
        end

        function xyz = getDAspect(obj, ax)
            % GETDASPECT
            %   Scales a plot by x,y,z dimensions
            % Optional inputs:
            %   ax      axesHandle to apply daspect
            % ----------------------------------------------------------
            % xyz = obj.volumeScale/max(abs(obj.volumeScale));
            xyz = max(obj.volumeScale)./obj.volumeScale;
            if nargin == 2
                assert(isa(ax, 'matlab.graphics.axis.Axes'),...
                    'Input an axes handle');
                daspect(ax, xyz);
            end
        end
    end
end