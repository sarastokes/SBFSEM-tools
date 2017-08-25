function result = analyzeDF(data, nbins)
% analyze a neuron's dendritic field
% INPUTS:
%   data        Neuron object OR {Neuron, xyz, ind}
% NOTE: Axons still need to be removed manually (data brush, then use
% rmNaN)
%
% 12Aug2017 - SSP - created
% 25Aug2017 - SSP - now used in DendriticFieldHull method

if nargin < 2
    nbins = [];
end

if isa(data, 'Neuron')
    neuron = data;
    xyz = data.dataTable.XYZum;
    ind = [];
else
    neuron = data{1};
    xyz = data{2};
    if numel(data) > 2
        ind = data{3};
    else
        ind = [];
    end
end

% for most neurons this is fine, however, some of the larger cells on
% the slope may need to be projected onto a more accurate plane
xy = xyz(:,1:2);

k = convhull(xy(:,1), xy(:,2));
A = polyarea(xy(k,1), xy(k,2));

    figure(); hold on;
    scatter(xy(:,1), xy(:,2), '.k');
    plot(xy(k,1), xy(k,2), 'b', 'LineWidth', 2);
    title(sprintf('area = %.2f um^2', A));
    
% dendrite diameter analysis
dendriteSizes = neuron.dataTable.Size;
if ~isempty(ind)
    dendriteSizes(ind) = [];
end
if ~isempty(nbins)
    [n, edges] = histcounts(dendriteSizes, nbins);
else
    [n, edges] = histcounts(dendriteSizes);
end

figure(); hold on;
plot(edges(2:end), n, 'k', 'LineWidth', 1);

if nargout == 1
    result.k = k;
    result.A = A;
    result.n = n;
    result.edges = edges;
    result.ds = dendriteSizes;
end


