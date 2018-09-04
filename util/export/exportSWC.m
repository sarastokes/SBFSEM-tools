function exportSWC(neuron, fname, fpath)
	% EXPORTSWC  Export neuron in SWC format

	assert(isa(neuron, {'NeuronAPI'}), 'Input a Neuron');
	if strcmp(fname(end-3:end), '.swc')
		fname = [fname, '.swc'];
	end
	if nargin < 3
		fpath = cd;
	end

	% Create the header
	fid = fopen([fpath filesep fname]);
	fprintf(fid, '# ORIGINAL_SOURCE Matlab sbfsem_tools\n');
	fprintf(fid, '# CREATURE\n');
	fprintf(fid, '# REGION\n');
	fprintf(fid, '# FIELD/LAYER\n');
	fprintf(fid, '# TYPE\n');
	fprintf(fid, '# CONTRIBUTOR\n');
	fprintf(fid, '# REFERENCE\n');
	fprintf(fid, '# RAW\n');
	fprintf(fid, '# EXTRAS\n');

	% TODO: figure out how to use this field
	fprintf(fid, '# SOMA_AREA\n');
	fprintf(fid, '# SHRINKAGE_CORRECTION 1.0 1.0 1.0\n');
	fprintf(fid, '# VERSION_NUMBER 1.0\n');

	fprintf(fid, ['# VERSION_DATE ',... 
		datestr(now, 'yyyy-mm-dd') '\n']);

	volumeScale = readOData(getODataURL(...
		neuron.ID, neuron.source, 'scale'));
	
	fprintf(fid, ['# SCALE ',... 
		num2str(volumeScale.X.value), ' ',...
		num2str(volumeScale.Y.value), ' ',...
		num2str(volumeScale.Z.value), '\n']);

	% 