% ---------------------------
% Dendritic Diameter Tutorial
% ---------------------------
% This is meant to be run line by line.
% 4Sept2018 - SSP

% Load in an amacrine cell from NeitzTemporalMonkey 
c4781 = Neuron(4781, 't');

% Get the Dendrite Diameter analysis object
a = sbfsem.analysis.DendriteDiameter(c4781);
% You should see statistics print to the command line. If you want to see
% these again later, just type in:
a.report();

% Use the plot method to visualize the output.
a.plot();
% By default, plots with SEM. To see SD instead:
a.plot('SD', true);
% The bin containing the soma annotations will be much larger. To plot 
% without the first bin:
a.plot('SD', true, 'includeSoma', false);
% To plot the median as well
a.plot('median', true, 'includeSoma', false);

% Click around on the objects inside the 'data' structure to get an idea of
% the information provided by this analysis. If you'd like to program your
% own analyses familiarity with these numbers will be essential.
openvar('a')

% You could also copy & paste these numbers to Excel for further analysis. 
% To assist with this, I added a function to create an easily copyable
% table of the results. binCenters is in microsn
T = a.table();
openvar('T')

% There are many additional options in the DendriteDiameter calculation. 
% At this point, make sure to read the information included in the
% DendriteDiameter documentation, which can be reached by help().
help('sbfsem.analysis.DendriteDiameter')
% You can also view the help for specific functions by appending them 
% to the class name like so:
help('sbfsem.analysis.DendriteDiameter/plot')s
help('sbfsem.analysis.DendriteDiameter/includeSoma')

% Increase the number of bins (experiment with this parameter)
a.doAnalysis(c4781, 'nbins', 15);
x.plot();

