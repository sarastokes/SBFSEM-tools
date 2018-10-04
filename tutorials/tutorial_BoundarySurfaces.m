% IPL Boundary Tutorial
%
% 14Sept2018 - SSP
% 4Oct2018 - SSP - added cachedcall instructions

% Initialize with volume name or abbreviation
GCL = sbfsem.builtin.GCLBoundary('i');

% Same for the IPL-INL boundary markers
INL = sbfsem.builtin.INLBoundary('i');

% Analyze, input is number of interpolation points.
INL.doAnalysis(200);
GCL.doAnalysis(200);

% Create a blank figure
ax = axes('Parent', figure());

% Add the GCL boundary with data
GCL.plot('ax', ax, 'ShowData', true);
% Can also plot without data. Plot INL this way.
INL.plot('ax', ax);

% Helpful for visualization
grid on;

% --------------------
% Once the boundary markers are in place and no longer changing,
% updating constantly from OData is no longer necessary. To avoid the 
% long wait times, use cachedcall to save the results of the query
GCL = cachedcall(@sbfsem.builtin.GCLBoundary, 'i');
INL = cachedcall(@sbfsem.builtin.INLBoundary, 'i');

% This default directory is your temporary folder
fprintf('Cache is saved to: \n\t%s\n', tempdir);

% To save somewhere else, use:
GCL = cachedcall(@sbfsem.builtin.GCLBoundary, 'i',... 
	'CacheFolder', 'C:\Users\...');