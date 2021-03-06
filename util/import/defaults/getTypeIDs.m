function T = getTypeIDs()
	% GETTYPEIDS  Returns a table of Viking Type IDs
	%
	% 30Sept2017 - SSP

	T = {3, 'Blood Vessel';...
        28, 'Gap Junction';...
        34, 'Conventional Presynapse';...
        35, 'Postsynapse';...
        73, 'Ribbon';...
        81, 'Organized SER';...
        85, 'Adherens';...
        181, 'Cistern Pre';...
        182, 'Cistern Post';...
        183, 'Cilium';...
        189, 'BC Conventional Synapse';...
        219, 'Multicistern';...
        220, 'Endocytosis';...
        225, 'Multivesicular Body';...
        226, 'Ribosome Patch';...
        227, 'Ribbon Cluster';...
        229, 'Touch';...
        230, 'Loop';...
        232, 'Polysomes';...
        236, 'Plaque';...
        237, 'Axon';...
        240, 'Plaque-like Pre';...
        241, 'Plaque-like Post';...
        243, 'Neuroglial Adherens';...
        244, 'Unknown';...
        245, 'Nucleolus';...
        246, 'Mitochondria';...
        253, 'Annular Gap Junction'};
    T = table(T(:,1), T(:,2));
    T.Properties.VariableNames = {'ID', 'Name'};