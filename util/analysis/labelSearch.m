%% Script to search for cells by label.

% Specify the volume to search:
disp(['valid options'])
disp(['     t     = TemporalMonkey2'])
disp(['     i     = InferiorMonkey'])
disp(['     n     = NasalMonkey'])
disp(['     cped  = Neitzcped'])
volume = input('Please enter the volume abbreviation: ','s')
disp(['You entered: ', volume]);
x = sbfsem.io.OData(volume);

% Specify the label to search. Include false if 
% not looking for an exact match

label = input('Please enter the label to be searched for: ', 's')
disp(['You entered: ', label])
idList = x.idsByLabel(label, false)
openvar('idList');