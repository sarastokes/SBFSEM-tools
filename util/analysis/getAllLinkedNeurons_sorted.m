%% Perform a getAllLinkedNeurons.m search - Sorted and Exported
% Name: getAllLinkedNeurons_sorted.m
% To run: >> getAllLinkedNeurons_sorted()
% History:
% Jun-02-2026: Created, using labelSearch_sorted.m as a template

% Display valid volume options
fprintf('Valid volume options:\n');
fprintf('  t    = TemporalMonkey2\n');
fprintf('  i    = InferiorMonkey\n');
fprintf('  n    = NasalMonkey\n');
fprintf('  cped = Neitzcped\n');

% Prompt user for volume and validate input
validVolumes = {'t', 'i', 'n', 'cped'};
volume = lower(strtrim(input('Enter volume abbreviation: ', 's')));
if ~ismember(volume, validVolumes)
    error('Invalid volume. Please enter one of: t, i, n, cped.');
end
fprintf('You entered: %s\n', volume);

% Prompt user for Cell ID and convert to number
idStr = strtrim(input('Enter the cell ID to search for: ', 's'));
ID = str2double(idStr);
if isnan(ID)
    error('Invalid cell ID. Please enter a numeric value.');
end
fprintf('You entered: %d\n', ID);

% Construct Neuron object and run getAllLinkedNeurons
neuron = Neuron(ID, volume, true);
synTable = getAllLinkedNeurons(neuron);

% Display results
fprintf('Found %d linked synapses.\n', height(synTable));
openvar('synTable'); % Open in variable editor

% Optional: Save results
saveOption = lower(strtrim(input('Would you like to save the results? (y/n): ', 's')));
if strcmp(saveOption, 'y')
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

    % Save based on file type
    switch fileType
        case 'csv'
            writetable(synTable, fullPath);
        case 'xlsx'
            writetable(synTable, fullPath);
        case 'mat'
            save(fullPath, 'synTable');
    end
    fprintf('Results saved successfully to:\n%s\n', fullPath);
end
