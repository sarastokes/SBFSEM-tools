%% getContributions tutorial
% 19Nov2018 - SSP

% SYNTAX:
%   getContributions(ID, source, visualize)
%
% where cell ID is the structure ID number and volume name is either the 
% full volume names ('NeitzInferiorMonkey', 'NeitzTemporalMonkey') or 
% abbreviation ('i', 't', respectively). visualize is either true/false. If
% a 3rd argument isn't provided, the default is 'true'. This determines
% whether to plot a pie chart of the annotators

% c5370 in InferiorMonkey
getContributions(5370, 'i');
% c121 in TemporalMonkey
getContributions(121, 't');

% If you wanted to look at multiple cells, you can use the table output and
% copy/paste that into excel
T = getContributions(5370, 'i');
openvar('T');  % Show in Matlab's VariableViewer