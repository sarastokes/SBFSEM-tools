%% Search for Cells by Label - Sorted and Exported

% Name:  labelSearch_sorted.m

% To run:  >> labelSearch_sorted()

% History:
% Jun-04-2025: Enhanced by Copilot to include validation, saving, and formatting


% Display valid volume options
fprintf('Valid volume options:\n');
fprintf('  t     = TemporalMonkey2\n');
fprintf('  i     = InferiorMonkey\n');
fprintf('  n     = NasalMonkey\n');
fprintf('  cped  = Neitzcped\n');

% Prompt user for volume and validate input
validVolumes = {'t', 'i', 'n', 'cped'};
volume = lower(strtrim(input('Enter volume abbreviation:', 's')));
if ~ismember(volume, validVolumes)
error('Invalid volume. Please enter one of: t, i, n, cped.');
end
fprintf('You entered: %s\n', volume);

% Create OData object
x = sbfsem.io.OData(volume);

% Prompt user for label
label = strtrim(input('Enter the label to search for: ', 's'));
if isempty(label)
error('Label cannot be empty.');
end
fprintf('You entered: %s\n', label);

% Search for IDs by label (non-exact match)
idList = x.idsByLabel(label, false);

% Display results

fprintf('Found %d matching IDs.\n', numel(idList));
openvar('idList'); % Open in variable editor


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

% Convert to table for saving
idTable = table(idList(:), 'VariableNames', {'CellID'});

% Save based on file type
switch fileType
case 'csv'
writetable(idTable, fullPath);
case 'xlsx'
writetable(idTable, fullPath);
case 'mat'
save(fullPath, 'idList');
end

fprintf('Results saved successfully to:\n%s\n', fullPath);
end