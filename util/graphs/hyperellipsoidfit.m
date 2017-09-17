function [Me, oe, success, A, regParam, dist] = ...
    hyperellipsoidfit(data, ...
    regularization, ...
    method, ...
    varargin)
%HYPERELLIPSOIDFIT Fitting of N-dimensional ellipsoid
%   HYPERELLIPSOIDFIT(D) fits an N-dimensional 
%   hyperellipsoid to collection of N-dimensional data 
%   points given in variable D using a least-squares method 
%   described in 
%       Martti Kesniemi and Kai Virtanen,
%       "Direct Least Square Fitting of Hyperellipsoids,"
%       IEEE Transactions on Pattern Analysis and Machine Intelligence,
%       Preprint, DOI: 10.1109/TPAMI.2017.2658574.
%   With input variable D, it is assumed that number of data points > 
%   number of dimensions, and the matrix is translated accordingly.
%
%   HYPERELLIPSOIDFIT(D, R) uses a sphere-favoring regularization method to
%   increase the possibility to get a solution describing a hyperellipsoid,
%   and to obtain a solution for underdetermined problems.
%   R is the regularization parameter with default value 'eps'. Value 
%   'auto' uses Gander determination for the regularization parameter, 
%   described in. 
%       W. Gander, G. H. Golub and R. Strebel, 
%       Least-Squares Fitting of Circles and Ellipses, 
%       BIT Numerical Mathematics, vol. 32, no. 4, pp. 558-578, Dec. 1994.
%   Also negative values may be used to avoid spherical solutions.
%
%   HYPERELLIPSOIDFIT(D, R, M) uses the method chosen through
%   string M, where valid values for M are
%   'SOD': Default, Sum-Of-Discriminants. Described in 2D by
%       A. Fitzgibbon, M. Pilu, and R.B. Fisher, 
%       Direct Least Square Fitting of Ellipses, 
%       IEEE Trans. Pattern Analysis and Machine Intelligence, 
%       vol. 21, no. 5, pp. 476-480, May 1999.
%   'HES': Ellipsoid-specific method. Described in 3D by
%       Q. Li and J.G. Griffiths, 
%       Least Square Ellipsoid Spicific Fitting, 
%       Proc. IEEE Geometric Modeling and Processing, 
%       pp. 335-340, 2004.
%       Parameter eta can be used to loosen the ellipticity constraint.
%       With eta = inf, HES equals to SOD.
%   'BOOK': Quadratic constraint described in
%       F.L. Bookstein, Fitting Conic Sections to Scattered Data, 
%       Computer Graphics and Image Processing, no. 9, pp. 56-71, 1979.
%   'TAUB': Quadratic constraint described in
%       G. Taubin, Estimation of Planar Curves, Surfaces, 
%       and Non-planar Space Curves Defined by Implicit Equations 
%       with Appli-cations to Edge and Range Image Segmentation, 
%       IEEE Trans. Pattern Analysis and Machine Intelligence, 
%       vol. 13, no. 11, pp. 1115-1138, Nov. 1991.
%       Usage of the regularization is not recomended with the Taubin
%       method.
%   'FC': Fixed constant term, described in
%       P.L. Rosin, A Note on the Least Squares Fitting of Ellipses, 
%       Pattern Recognition Letters, vol. 14, no. 10, pp. 799-808, 
%       Oct. 1993.
%   '2-NORM': 
%       Fixed sum-of-squares.       
%
%   [Me, oe, success, A, regCoeff] = HYPERELLIPSOIDFIT returns the matrix 
%   Me and offset oe that maps points located on the surface of an unit 
%   hypersphere to the surface of the estimated ellipsoid, 
%   y = Me * x + oe;
%   If the solution doesn't decribe an ellipsoid, success is false,
%   otherwise success is true;
%   Parametric form of the quadric surface fitted to the data or 
%   normalized data is returned in vector A; 
%   Regularization parameter used is returned in regParam.
%
%   Other control parameters:
%   hyperellipsoidfit(D, M, R, ...
%       'eta', etaValue [1, inf], ...
%       'normalize', [true/false], ...
%       'forceOrigin', [true/false], ...
%       'forceAxial', [true/false])
%   eta: controls the constraint assuring hyperellipsoid specificity
%       with HES. eta = 1 assures the ellipsoid-specifity, and eta = inf 
%       equals to SOD. Valid values: eta >= 1. 
%       Default: eta = 1.
%   normalize: if false, input data is not normalized (centered and
%       scaled). 
%       Default: normalize = true.
%   forceAxial: if true, ellipsoid axis are fixed to coordinate axis.
%       Default: forceAxial = false.
%   forceOrigin: if true, ellipsoid center is fixed to origin.
%       Default: forceOrigin = false.
%   Pass [] to use the default value with any of the parameters.
%
%   Copyright 2014-2017 by Martti Kesniemi
%

% Initialize and set defaults
persistent p; % Dimensionality-dependent constants

%%% Parse input %%%
if nargin < 1
    error('At least one input required!');
end;
if nargin < 2 || isempty(method),
    method = 'SOD';
end;
if nargin < 3 || isempty(regularization),
    regularization = eps;
elseif strcmp(method, 'TAUB')
    warning('hyperellipsoidfit:params', ...
        'Regularization is not recommended with method ''TAUB''');
end;
eta = 1;
normalize = true;
forceOrigin = false;
forceAxial = false;
varargin_ = varargin;
while length(varargin) >= 2
    param = lower(varargin{1});
    switch param
        case 'eta'
            val = varargin{2};
            eta = val;
            if eta < 1.0,
                error('Eta parameter value has to be >= 1.')
            end;
            if ~strcmp(method, 'HES')
                warning('hyperellipsoidfit:params', ...
                    ['Parameter ''eta'' is ignored with other' ...
                    ' methods than the method ''HES''']);
            end;
        case 'normalize'
            val = varargin{2};
            normalize = (val ~= 0);
        case 'forceorigin'
            val = varargin{2};
            forceOrigin = (val ~= 0);
        case 'forceaxial'
            val = varargin{2};
            forceAxial = (val ~= 0);
        otherwise
            error('Unknown parameter (%s)!', param);
    end 
    varargin = varargin(3:end);
end
if forceOrigin && normalize, 
    if any(strcmp(varargin_, 'normalize')),
        warning('hyperellipsoidfit:params', ...
            'Normalizing only the scale when fit forced to origin');
    end;
end;
%%% End of input parsing %%%

Me = 0; oe = 0; dist = inf;
success = false;

% Translate input matrix if seems appropriate
if (size(data,2) > size(data,1))
    data = data';
end;

if normalize,
    if forceOrigin,
        [data, means, scales] = NormalizeData(data, false);
    else
        [data, means, scales] = NormalizeData(data);
    end;
else
    means = zeros(1,size(data,2));
    scales = ones(1,size(data,2));
end;

if isempty(p) 
    p = struct( ...
        'nDim', nan, ...
        'crossInds', nan, ...
        'nCrossTerms', nan, ...
        'nDSize', nan, ...
        'regMatrix', nan, ...
        'epsilon', nan, ...
        'crossTerms', nan, ...
        'forceOrigin', nan, ...
        'forceAxial', nan);
end;
if p.nDim ~= size(data,2) ...
        || p.forceOrigin ~= forceOrigin ...
        || p.forceAxial ~= forceAxial, 
    % Initialize dimension-related parameters
    p.nDim = size(data,2);
    p.crossInds = nchoosek(1:p.nDim, 2);
    if forceAxial,
        p.nCrossTerms = 0;
    else
        p.nCrossTerms = size(p.crossInds,1);
    end;
    p.forceAxial = forceAxial;
    if forceOrigin
        p.nDSize = p.nDim + p.nCrossTerms + 1;
    else
        p.nDSize = p.nDim + p.nCrossTerms + p.nDim + 1;
    end;
    p.forceOrigin = forceOrigin;
    
    % Create regularization matrix
    tmp = p.nDSize;
    p.regMatrix = zeros(tmp);
    p.regMatrix(1:p.nDim, 1:p.nDim) = -2;
    p.regMatrix((0:(p.nDim-1))*(tmp+1)+1) = 2*(p.nDim-1);
    p.regMatrix((p.nDim + (0:(p.nCrossTerms-1))) * (tmp+1)+1) = ...
        p.nDim;
    p.epsilon = exp(log(eps)/2);
end;

% Compute second order cross terms
p.crossTerms = zeros(size(data,1), p.nCrossTerms);

for ii = 1:p.nCrossTerms,
    p.crossTerms(:,ii) = data(:,p.crossInds(ii,1)) .* ...
        data(:,p.crossInds(ii,2));
end;

if strcmp(regularization, 'auto')
    regParam = eps;
else
    regParam = regularization;
end;

% Loop for searching the regularization parameter when 
% regularization == 'auto'
while (1),
    % Solve fitting problem according to the selected method
    switch method,
        case {'HES', 'ES', 'SOD', 'BOOK', 'Bookstein'},
            [ A, sucs ] = ...
                QuadraticConstraint(...
                data, p, ...
                regParam, ...
                method, eta);
        case {'Taubin', 'TAUB'}
            [ A, sucs ] = ...
                TaubinConstraint(...
                data, p, ...
                regParam);
        case {'2-NORM'}
            [ A, sucs ] = ...
                LlsSolution(...
                data, p, ...
                regParam);
        case {'FC', 'Rosin'},
            [ A, sucs ] = ...
                LinearConstraint(...
                data, p, ...
                regParam);
        otherwise,
            error('Unknown fitting method %s!', method);
    end;
    
    if sucs
        % Choose sign of solution vector
        if (A(1) < 0)
            A = -A;
        end;
        if any(GetDiscriminants(A, p) < eps)
            sucs = false;
        else
            break;
        end;
    end;
    if ~sucs
        if strcmp(regularization, 'auto')
            if regParam <= eps,
                regParam = 1e-3;
            else
                regParam = regParam*1.1;
                if (regParam > 1)
                    return;
                end;
            end;
        else
            warning('hyperellipsoidfit:failed', ...
                'Failed to find an ellipsoidal solution')
            return;
        end;
    end;
end;

% Get distance
if nargout > 5,
    if p.forceOrigin
        D = [data.^2 p.crossTerms -ones(size(data,1),1)];
    else
        D = [data.^2 p.crossTerms data -ones(size(data,1),1)];
    end;    
    dist = D*A;
end;

% Solve algebraic form
[Me, oe] = GetMappingForm(A', p);
Me = Me*mean(scales);
oe = oe*mean(scales) + means';
success = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ A, success ] = LinearConstraint(...
    ndata, p, ...
    regularization)

success = false;

if p.forceOrigin
    D = [ndata.^2 p.crossTerms];
else
    D = [ndata.^2 p.crossTerms ndata];
end;

% Regularization matrix is smaller with linear constraint
TT = p.regMatrix(1:(end-1),1:(end-1));

S = ( D' * D ) + ...
    regularization * TT;

lastwarn('');
A = S \ ( D' * ones( size( ndata, 1 ), 1 ) );
[~, msgid] = lastwarn;
A = [A; 1];
if strcmp(msgid, 'MATLAB:nearlySingularMatrix') ...
        || strcmp(msgid, 'MATLAB:singularMatrix'),
    return;
end;

success = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ A, success ] = QuadraticConstraint(...
    ndata, p, ...
    regularization, ...
    method, eta)

success = false;

A = zeros(p.nDim,1);
if p.forceOrigin
    D = [ndata.^2 p.crossTerms -ones(size(ndata,1),1)];
else
    D = [ndata.^2 p.crossTerms ndata -ones(size(ndata,1),1)];
end;

% Populate constraint matrix according to the method
constrMatrix = zeros(p.nDSize);

switch method
    case {'HES', 'ES', 'SOD'},
        switch method
            case {'HES', 'ES'}
                % I: alpha = 2*(4-2*n) + 4*(n-1)*eta
                %          = 8 - 4*n + 4*n*eta - 4*eta
                %          = 4 * ((2-n) + (n-1)*eta)
                % J: beta  = 4-2*n
                % K: gamma = (1-n)*eta
                alpha =     4*((2 - p.nDim)/eta + (p.nDim-1));
                beta  =     (4 - 2*p.nDim) / eta;
                gamma =     1 - p.nDim;
            case 'SOD'
                alpha =     4;
                beta  =     0;
                gamma =    -1;
        end;
        constrMatrix(1:p.nDim, 1:p.nDim) = alpha/2;
        constrMatrix((0:(p.nDim-1))*(p.nDSize+1)+1) = beta;
        constrMatrix((p.nDim+(0:(p.nCrossTerms-1)))*...
            (p.nDSize+1)+1) = gamma;
    case {'BOOK', 'Bookstein'}
        constrMatrix((0:(p.nDim-1))*(p.nDSize+1)+1) = 1;
        constrMatrix((p.nDim+(0:(p.nCrossTerms-1))) * ...
            (p.nDSize+1)+1) = 1/2;
    otherwise,
        error('Unknown method');
end;

% Form scatter matrix
S = D' * D;

% Solve eigensystem
nQuadTerms = p.nDim + p.nCrossTerms;
% Break into blocks
if p.forceOrigin
    linTerms = 0;
else
    linTerms = p.nDim;
end;
C1 = constrMatrix(1:nQuadTerms,1:nQuadTerms);    
% quadratic part of the constraint matrix
S1 = S(1:nQuadTerms,1:nQuadTerms);    
% quadratic part of the scatter matrix
S2 = S(1:nQuadTerms,...
    nQuadTerms+(1:(linTerms+1)));           
% combined part of the scatter matrix
S3 = S(nQuadTerms+(1:(linTerms+1)),...
    nQuadTerms+(1:(linTerms+1)));           
% linear part of the scatter matrix

lastwarn('');
TS = -S3 \ S2';            % for getting a2 from a1
[~, msgid] = lastwarn;
if strcmp(msgid, 'MATLAB:nearlySingularMatrix') ...
        || strcmp(msgid, 'MATLAB:singularMatrix'),
    warning('hyperellipsoidfit:failed', ...
        'Ill-conditioned scatter matrix linear part!');
    return;
end;

if regularization ~= 0
    TT = p.regMatrix(1:nQuadTerms, 1:nQuadTerms);
    M = S1 + S2 * TS + regularization * TT; % reduced scatter matrix
else
    M = S1 + S2 * TS;           % reduced scatter matrix
end;

[evec, eval] = eig(M, C1);  % solve eigensystem

switch method
    case {'BOOK', 'Bookstein'}
        [a1, success] = ChooseSmallestEigenvalue(evec, eval, p);
    otherwise
        [a1, success] = ChoosePositiveEigenvalue(evec, eval, p);
end;

if ~success
    return;
end;

A = [a1; TS * a1];      % ellipse coefficients

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ A, success ] = TaubinConstraint(...
    ndata, p, regularization)

if p.forceOrigin
    D = [ndata.^2 p.crossTerms -ones(size(ndata,1),1)];
else
    D = [ndata.^2 p.crossTerms ndata -ones(size(ndata,1),1)];
end;

% Populate constraint matrix with partial derivatives
constrMatrix = zeros(size(D, 2));
nofData = size(ndata,1);
for ii = 1:p.nDim,
    CT = zeros(nofData, p.nCrossTerms);
    if ~p.forceAxial,
        dInds1 = find(p.crossInds(:,1) == ii);
        dInds2 = find(p.crossInds(:,2) == ii);
        CT(:,dInds1) = ndata(:,p.crossInds(dInds1,2));
        CT(:,dInds2) = ndata(:,p.crossInds(dInds2,1));
    end;
    if p.forceOrigin,
        tmp = ...
            [zeros(nofData, ii-1), 2*ndata(:,ii), ...
            zeros(nofData, p.nDim-ii), ...
            CT, ...
            zeros(nofData,1)];
    else
        tmp = ...
            [zeros(nofData, ii-1), 2*ndata(:,ii), ...
            zeros(nofData, p.nDim-ii), ...
            CT, ...
            zeros(nofData, ii-1), ones(nofData,1), ...
            zeros(nofData, p.nDim-ii), ...
            zeros(nofData,1)];
    end;
    constrMatrix = constrMatrix + tmp'*tmp;
end;
% Form scatter matrix
S = D' * D;
if regularization ~= 0
    S = S + regularization * p.regMatrix; % reduced scatter matrix
end;
[evec, eval] = eig(S,constrMatrix);
[A, success] = ChooseSmallestEigenvalue(evec, eval, p);

% solve inverted eigensystem
%[evec, eval] = eig(constrMatrix, S); 
%[A, success] = ChooseSmallestEigenvalue(evec, 1./eval, p);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ A, success ] = LlsSolution(...
    ndata, p, regularization)

if p.forceOrigin
    D = [ndata.^2 p.crossTerms -ones(size(ndata,1),1)];
else
    D = [ndata.^2 p.crossTerms ndata -ones(size(ndata,1),1)];
end;

% Form scatter matrix
S = D' * D;
if regularization ~= 0
    S = S + regularization * p.regMatrix; % reduced scatter matrix
end;

[evec, eval] = eig(S); % solve eigensystem
[A, success] = ChooseSmallestEigenvalue(evec, eval, p);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ a, success ] = ChooseSmallestEigenvalue(evec, eval, p)

success = false; a = [];
eval = diag(eval);

% Find finite real positive eigenvalues
I = find(isfinite(eval) ...
    & abs(imag(eval)) < p.epsilon ...
    & eval > -p.epsilon);

% Get smallest eigenvalue
if (numel(I) > 1)
    [~, II] = min(real(eval(I)));
    I = I(II);
elseif isempty(I)
    warning('hyperellipsoidfit:failed','No suitable eigenvalues!');
    return;
end;

a = real(evec(:, I));  % eigenvector for min. pos. eigenvalue
% Assure it creates an ellipsoid
condnums = GetDiscriminants(evec(:,I), p);
if any(condnums < 0)
    return;
end;

success = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ a, success ] = ChoosePositiveEigenvalue(evec, eval, p)

success = false; a = [];
eval = diag(eval);
evec = real(evec);

% Get index of the positive real finite eigenvalue
% (which may be slightly negative in case of perfect fit!)
I = find(isfinite(eval) ...
    & eval > -p.epsilon ...
    & abs(imag(eval)) < p.epsilon);
if isempty(I)
    return;
end;

% Drop non-ellipsoidal ones
for ii = 1:numel(I),
    if any(GetDiscriminants(evec(:,I(ii)), p) < 0)
        I(ii) = nan;
    end;
end;
I = I(isfinite(I));
if isempty(I)
    [~, II] = max(real(eval));
    a = evec(:, II);  % eigenvector corresponding to largest eigenvalue
    return;
end;
    
% If still more than one, choose largest one
[~, II] = max(real(eval(I)));
I = I(II);

a = evec(:, I);  % eigenvector corresponding to chosen eigenvalue

% Assure it creates an ellipsoid
if any(GetDiscriminants(evec(:,I), p) < 0)
    return;
end;

success = true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sdata, means, scales] = NormalizeData(data, bMeans, bScale)

if nargin < 2 || isempty(bMeans),
    bMeans = true;
end;    
if nargin < 3 || isempty(bScale),
    bScale = true;
end;
    
if bMeans,
    means  = mean(data);
    sdata  = bsxfun(@minus, data, means);
else
    means = zeros(1, size(data,2));
    sdata = data;
end;
if bScale,
    scale  = (max(sdata(:))-min(sdata(:)))/2;
    sdata  = sdata/scale;
else
    scale = 1;
end;
scales = scale * ones(1, size(data, 2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ d ] = GetDiscriminants( v, p )

if p.forceAxial, %All cross terms are zero, but discrs must still be > 0
    d = zeros(size(v,2), size(p.crossInds,1));
    for ii = 1:size(p.crossInds,1),
        d(:,ii) = v(p.crossInds(ii,1),:) .* v(p.crossInds(ii,2),:);
    end;
else
    d = zeros(size(v,2), p.nCrossTerms);
    for ii = 1:p.nCrossTerms,
        d(:,ii) = 4 * v(p.crossInds(ii,1),:) .* v(p.crossInds(ii,2),:) - ...
            v(p.nDim+ii,:).^2;
    end;
end;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Me, oe] = GetMappingForm( v, p )

% Scale v
v = v/v(end);
v((p.nDim+1):(end-1)) = v((p.nDim+1):(end-1))/2;

% Form matrix A in [x,1]'*A*[x,1] = 0
A = diag([v(1:p.nDim) -1]);
for ii = 1:p.nCrossTerms,
    A(p.crossInds(ii,1), p.crossInds(ii,2)) = v(p.nDim+ii);
    A(p.crossInds(ii,2), p.crossInds(ii,1)) = v(p.nDim+ii);
end;
if p.forceOrigin,
    A(end, 1:p.nDim) = 0;
    A(1:p.nDim, end) = 0;
else
    A(end, 1:p.nDim) = v((p.nDim+p.nCrossTerms+1):(end-1));
    A(1:p.nDim, end) = v((p.nDim+p.nCrossTerms+1):(end-1));
end;

if ~p.forceOrigin,
    % get offset
    oe = -A( 1:p.nDim, 1:p.nDim ) \ v((end-p.nDim):(end-1))';
    % Remove offset
    T = eye( p.nDim+1 );
    T( p.nDim+1, 1:p.nDim ) = oe';
    R = T * A * T';
    R = R( 1:p.nDim, 1:p.nDim ) / -R( p.nDim+1, p.nDim+1 );
else
    oe = zeros(p.nDim,1);
    R = A(1:p.nDim, 1:p.nDim);
end;

% solve Me from Me'*Me = R
[~, S, V] = svd(R);
Me = real(V * diag(1./sqrt(diag(S))) * V');

end