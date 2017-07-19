function pajekNET(neuron)
	% export the contact matrix into pajek .net format
	% for use with infomap etc
	% INPUTS: 
	% 		neuron 			Neuron object with connectivity data
	% OPTIONAL:
	%			fname 			include a filename to trigger save dlg
	%
	% Edges are undirected, Arcs are directed
	% From, To, Weight (example: 1 2 1.0)
	% 1 is default weight, duplicates are aggregated
	%
	% Nodes are called Vertices
	% #, "Name" Weight (example: 1 "Node 1" 1.0)
	% Node weight (default 1) sets teleportation proportion
	% 
	% NOTE: I'm putting everything as an arc,
	% undirected nodes will be listed twice as A B and B A
	%
	% 17Jul2017 - SSP - created

	nt = neuron.conData.nodeTable.NodeTag; 
  
  fid = fopen(sprintf('c%uNET.txt', neuron.cellData.cellNum), 'w');

	fprintf(fid, '*Vertices %u\n', size(neuron.conData.contacts,1));
	for ii = 1:size(neuron.conData.nodeTable,1)
		fprintf(fid, '%u "%s"\n', ii, nt{ii});
	end
	fprintf(fid, '*Arcs %u\n', size(neuron.conData.contacts, 1));
	for ii = 1:size(neuron.conData.contacts,1)
		fprintf(fid, '%u %u %.1f\n', neuron.conData.contacts(ii,:),... 
			neuron.conData.edgeTable.Weight(ii));
	end

	fclose(fid);
