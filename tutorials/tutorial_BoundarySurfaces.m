% IPL Boundary Tutorial
%
% 14Sept2018 - SSP

% Initialize with volume name or abbreviation
GCL = sbfsem.builtin.GCLBoundary('i');
% Then load in the data
GCL.update();

% Same for the IPL-INL boundary markers
INL = sbfsem.builtin.INLBoundary('i');
INL.update();

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