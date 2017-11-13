function linklistTXT(neuron)
	% save as a link list .txt file
	% 
	% 	link list format:
	% 	#source target weight.
	% 	nodes are defined implicitly
	%
	%		pros: not as glitchy as pajek.net 
	%		cons: no node names
	%
	% 18Jul2017 - SSP - created

  fid = fopen(sprintf('c%uLink.txt', neuron.cellData.cellNum), 'w');
  for ii = 1:size(neuron.conData.contacts, 1)
  	fprintf(fid, '%u %u %.1f\n',... 
  		neuron.conData.contacts(ii,:),... 
  		neuron.conData.edgeTable.Weight(ii));
  end
  fclose(fid);

