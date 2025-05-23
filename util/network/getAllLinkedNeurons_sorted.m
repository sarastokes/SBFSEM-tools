% getAllLinkedNeurons_sorted.m

% History:
% May-21-2025:  created by Andrea S. Bordt using Microsoft Copilot

% In order to simplify generating getAllLinkedNeurons data, Copilot has helped create a new script that will:

% Ask the user to input the cell number (numerals only)
% Ask the user to input the volume identifier (t = TemporalMonkey2, i = InferiorMonkey, n = NasalMonkey, and c = cped)
% Create the cell object and import the linked cell data (>> cellID = Neuron, 'volume', true), followed by >> getAllLinkedNeurons(cellID)
% Sort the resulting table by SynapseType, then NeuronLabel, then NeuronID, and then SynapseID
% Ask the user for the desired filename
% Ask the user which file type they would like the table saved as (suggest using xlsx)
% Ask the user for the destination where the file should be saved
% Save the sorted table in the desired destination.

% The attached .m file can be downloaded and saved to your SBFSEM-tools folder, and then the Set Path within Matlab 
% would need to be reset (Home > Set Path > Add with subfolders > navigate to SBFSEM-tools on your computer > Save > Close). 

% The program can then be run within SBFSEM-tools by typing
% >> getAllLinkedNeurons_sorted()




% Prompt user for Cell ID and validate input
cellID = input('Enter Cell ID (numeric): ');
if ~isnumeric(cellID) || isempty(cellID) || ~isscalar(cellID)
    error('Invalid Cell ID. Please enter a single numeric value.');
end

% Prompt user for volume and validate input
validVolumes = {'t', 'i', 'n', 'cped'};
volume = lower(strtrim(input('Enter volume (t, i, n, or cped): ', 's')));
if ~ismember(volume, validVolumes)
    error('Invalid volume. Please enter one of the following: t, i, n, cped.');
end

% Create the Neuron object
neuronObj = Neuron(cellID, volume, true);

% Generate the table of linked neurons
T = getAllLinkedNeurons(neuronObj);

% Check if T is a table and contains required columns
requiredCols = {'SynapseType', 'NeuronLabel', 'NeuronID', 'SynapseID'};
if ~istable(T) || ~all(ismember(requiredCols, T.Properties.VariableNames))
    error('The returned data is not a valid table or is missing required columns.');
end

% Sort the table
sortedT = sortrows(T, requiredCols);

% Display the sorted table
disp(sortedT);

% Prompt user for file saving options
fileName = input('Enter file name (without extension): ', 's');
fileType = lower(strtrim(input('Enter file type (csv, xlsx, mat): ', 's')));
destination = input('Enter full path to destination folder: ', 's');

% Validate file type
validTypes = {'csv', 'xlsx', 'mat'};
if ~ismember(fileType, validTypes)
    error('Invalid file type. Choose from csv, xlsx, or mat.');
end

% Construct full file path
fullPath = fullfile(destination, [fileName '.' fileType]);

% Save the file based on type
switch fileType
    case 'csv'
        writetable(sortedT, fullPath);
    case 'xlsx'
        writetable(sortedT, fullPath);
    case 'mat'
        save(fullPath, 'sortedT');
end

fprintf('Sorted table saved successfully to:\n%s\n', fullPath);