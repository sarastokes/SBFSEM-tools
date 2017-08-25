function RS = reciprocalSynapses(neuron, varargin)
% RECIPROCALSYNAPSE  Finds candidate reciprocal synapses
%
%   INPUT:
%       neuron 		neuron object
%   OPTIONAL
%       cutoff		[0.5] search distance
%       unique 		[true] include only unique synapses
%   OUTPUT:
%       T			result table
%
%   The effective search distance is limited by the section width along the
%   z-axis. Default value of 0.5 um is from:
%
%   Tsukamoto & Oni (2014) OFF bipolar cells in macaque retina: Type-
%   specificconnectivity in the outer and inner synaptic layers. Frontiers
%   in Neuroanatomy, 10(104), 1-20
%
%   I increased this to 0.6 to make up for the Unique synapse distinction
%   so check up on any synapses in the 0.5-0.6 range before including them.
%
% 15Aug2017 - SSP - created


    ip = inputParser();
    ip.addParameter('cutoff', 0.6, @isnumeric);
    ip.addParameter('unique', 1, @islogical);
    ip.parse(varargin{:});
    cutoff = ip.Results.cutoff;
    flag = ip.Results.unique;

    T = neuron.dataTable;
    ribbon = strcmp(T.LocalName, 'ribbon pre')...
        & T.Unique == flag;
    conv = strcmp(T.LocalName, 'conv post')...
        & T.Unique == flag;
    
    ribbon = T(ribbon,:);
    conv = T(conv,:);

    RS = cell2table(cell(0,5));
    RS.Properties.VariableNames = {'N', 'Dist', 'Ribbon', 'Conv', 'ParentIDs'};

    for ii = 1:size(ribbon, 1)
        synDist = fastEuclid3d(ribbon(ii,:).XYZum, conv.XYZum);
        ind = find(synDist <= cutoff);
        if ind > 0
            RS = [RS; {numel(ind), synDist(ind),... 
                ribbon.LocationID(ii,:), conv.LocationID(ind,:)},...
                [ribbon.ParentID(ii,:), conv.ParentID(ind,:)]]; %#ok<AGROW>
        end
    end
    
    fprintf('Found %u reciprocal synapses of %u ribbon synapses\n',...
        sum(RS.N), size(ribbon,1));
