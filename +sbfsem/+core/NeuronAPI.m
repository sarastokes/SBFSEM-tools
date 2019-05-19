classdef (Abstract) NeuronAPI < sbfsem.core.StructureAPI
% NEURONAPI  
%
% Description:
%   Parent class for all Neuron object classes
%
% See also:
%   Neuron, sbfsem.core.StructureAPI
%
% History:
%   20Aug2018 - SSP
%   25Sept2018 - SSP - split into NeuronAPI and parent StructureAPI
% -------------------------------------------------------------------------

	properties (SetAccess = protected, GetAccess = public)
        % Attributes of each synapse
        synapses
	end

    properties (Constant = true, Hidden = true)
        STRUCTURE = 'Neuron';
    end

	properties (Dependent = true, Transient = true, Hidden = true)
 		somaRow 	% Largest "cell" annotation in node's row
 	end

	methods
		function obj = NeuronAPI(ID, source)
			% Maybe add link to Neuron factory later
            obj@sbfsem.core.StructureAPI(ID, source);
		end
    end

    % Soma methods
    methods
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

    % Synapse methods
    methods
        function checkSynapses(obj)
            % CHECKSYNAPSES  
            %   If synapses are missing but exist, import them
            %   Should be specified by subclasses
        end 

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
            %   syn             Synapse name or Structure ID number(s)
            %   useMicrons      Logical (default = true)
            %
            % Examples:
            %   % Return XYZ of all post-ribbon synapse annotations
            %   syn = obj.getSynapseXYZ('RibbonPost');
            %   % Return XYZ of a specific synapse ID
            %   syn = c1781.getSynapseXYZ(14796);
            %   % Return XYZ of several synapse IDs
            %   syn = c1781.getSynapseXYZ([14796, 14798]);
            % -------------------------------------------------------------
            if nargin < 3
                useMicrons = true;
            end
            obj.checkSynapses();

            % Find synapse structures matching synapse name
            if ischar(syn)
                syn = sbfsem.core.StructureTypes(syn);
            end
            
            if isa(syn, 'sbfsem.core.StructureTypes')                
                row = obj.synapses.LocalName == syn;
                IDs = obj.synapses.ID(row,:);
                % Find the unique instances of each synapse ID
                row = ismember(obj.nodes.ParentID, IDs) & obj.nodes.Unique;
            elseif isnumeric(syn)
                row = ismember(obj.nodes.ParentID, syn) & obj.nodes.Unique;
            end

            % Get the xyz values for only those rows
            if useMicrons
                xyz = obj.nodes{row, 'XYZum'};
            else
                xyz = obj.nodes{row, {'X', 'Y', 'Z'}};
            end
            if isempty(xyz)
                if isa(syn, 'sbfsem.core.StructureTypes')
                    warning('No locations found for %s\n', syn);
                else
                    warning('No locations found for %u\n', syn);
                end
                xyz = [NaN, NaN, NaN];
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
end