function linklistTXT2(neuron, varargin)
	% save as a link list .txt file w/ preferences
	% 
	% 	link list format:
	% 	#source target weight.
	% 	nodes are defined implicitly
	%
	%		pros: not as glitchy as pajek.net 
	%		cons: no node names
	%
	% 18Jul2017 - SSP - created
	% 25Jul2017 - SSP - added LocalName, used for simulation #2

	% 25Jul simulation:
	synOmit = {'adherens', 'desmosome', 'unknown', 'touch',... 
        'gaba fwd', 'neuroglial adherens'};

	nT = neuron.conData.nodeTable;
	eT = neuron.conData.edgeTable;

	% get the indices of unnamed nodes
	noName = [];
	for ii = 1:size(nT, 1)
		if ~any(isletter(char(nT.NodeTag(ii))))
			noName = cat(1, noName, ii);
		end
	end

	if ~isempty(synOmit)
		synList = ~ismember(eT.LocalName, synOmit);
	end

  fid = fopen(sprintf('c%uLink.txt', neuron.cellData.cellNum), 'w');
  for ii = 1:size(neuron.conData.contacts, 1)
  	% only the rows with traditional synapse names
  	if synList(ii)
  		% only the rows with named neurons
  		if isempty(find(noName == neuron.conData.contacts(ii,1)))...
  			&& isempty(find(noName == neuron.conData.contacts(ii,2)))
	  		fprintf(fid, '%u %u %.1f\n',... 
  				neuron.conData.contacts(ii,:),... 
  				neuron.conData.edgeTable.Weight(ii));
	  	end
	  end
  end
  fclose(fid);


