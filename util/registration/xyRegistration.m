function [data, S] = xyRegistration(source, sections, visualize)
% XYREGISTRATION
%
% Description:
%   Generate X,Y scale factors per section
%
% Syntax:
%   [data, S] = xyRegistration(source, sections, visualize);
%
% Inputs:
%   source              volume name or abbreviation
%   sections            start and stop section numbers (eg [1284 1305])
%   visualize           (false) graph output
%
% Outputs:
%   data                Nx3 matrix that is sent to updateRegistration
%                       where cols = Z, r
%
% OUTPUT:
%	S 		structure w/ mean, median, sd, sem, n
%   data    table of important information for final translation
%
% Notes:
%	UNITS ARE IN PIXELS! Must be applied before the micron conversion.
%
% History:
%   12Dec2017 - SSP
%   5Mar2017 - SSP - Updated for new JSON decoder
% -------------------------------------------------------------------------
    source = validateSource(source);
    if nargin < 3
        visualize = true;
    end

    str = sprintf('/Locations?$filter=Z le %u and Z ge %u and TypeCode eq 1',...
        max(sections), min(sections));

    data = webread([getServiceRoot(source), str,...
        '&$select=ID,ParentID,VolumeX,VolumeY,Z,Radius'],...
        getODataOptions());

    % Convert to a table
    T = struct2table(data.value);
    T.Properties.VariableNames = {'ID', 'ParentID', 'X', 'Y', 'Z', 'Radius'};

    % Catch false annotations with X/Y=0
    T(T.X == 0 | T.Y == 0, :) = [];

    % Initial list of neurons included in analysis
    neuronIDs = unique(T.ParentID);
    % Return annotation and cell counts
    fprintf('The query returned %u annotations from %u cells\n',...
        height(T), numel(unique(T.ParentID)));
    % And the number of cells with an annotation in each section
    % Later branching neurons will be addressed here but the immediate need
    % is for aligning in the area of bipolar cell somas without branches


    % Get the XY locations of each neuron at the most sclerad section
    zRef = T(T.Z == max(T.Z), {'ParentID', 'X', 'Y'});

    % Find neurons without annotations at the reference section
    invalidNeurons = setdiff(T.ParentID, zRef.ParentID);
    fprintf('Found %u neurons absent from reference section\n',...
        numel(invalidNeurons));
    % If present, remove the data from the analysis
    if ~isempty(invalidNeurons)
        T(ismember(T.ParentID, invalidNeurons), :) = [];
    end

    % Create arrays to hold the XY values relative to reference
    T.XShift = zeros(height(T), 1);
    T.YShift = zeros(height(T), 1);

    for i = 1:numel(neuronIDs)
        T(T.ParentID == neuronIDs(i), :).XShift = ...
            zRef{zRef.ParentID == neuronIDs(i), 'X'} -...
            T{T.ParentID == neuronIDs(i), 'X'};
        T(T.ParentID == neuronIDs(i), :).YShift = ...
            zRef{zRef.ParentID == neuronIDs(i), 'Y'} -...
            T{T.ParentID == neuronIDs(i), 'Y'};
    end

    % Analyze by section
    [sectionGroups, sectionIDs] = findgroups(T.Z);

    if visualize
        figure('Name', 'XY Image Registration');
        subplot(2,1,1); hold on;
        superbar(sectionIDs,...
            splitapply(@mean, T.XShift, sectionGroups),...
            'E', splitapply(@sem, T.YShift, sectionGroups));
        ylabel('X Offset (pix)');
        title('XY Image Registration');
        subplot(2,1,2); hold on;
        superbar(sectionIDs,...
            splitapply(@mean, T.YShift, sectionGroups),...
            'E', splitapply(@sem, T.YShift, sectionGroups));
        ylabel('Y Offset (pix)');
        xlabel('Section Number');
    end

    % Save mean, median, std, sem of x, y offset
    S = struct();
    S.sections = sectionIDs;
    S.xMean = splitapply(@mean, T.XShift, sectionGroups);
    S.yMean = splitapply(@mean, T.YShift, sectionGroups);
    S.xMedian = splitapply(@median, T.XShift, sectionGroups);
    S.yMedian = splitapply(@median, T.YShift, sectionGroups);
    S.xSD = splitapply(@std, T.XShift, sectionGroups);
    S.ySD = splitapply(@std, T.YShift, sectionGroups);
    S.xSEM = splitapply(@sem, T.XShift, sectionGroups);
    S.ySEM = splitapply(@sem, T.YShift, sectionGroups);
    S.N = splitapply(@numel, T.Z, sectionGroups);
    S.neurons = unique(T.ParentID);

    % The actual transformations to apply
    data = [S.sections, S.xMedian, S.yMedian];