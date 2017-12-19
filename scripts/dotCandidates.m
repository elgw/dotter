function [ P, meta ] = dotCandidates(varargin)
%dotCandidates(I, s)
% Locates local maxias in I according to the settings in s
% s.maxNpoints maximum number of points to be returned, 0 - no limit
% s.sigmadog size of kernel for DoG filter, typical 1.2
%
% Step 1: Local maximas are identified
% Step 2: Dots are ordered by some property
%
% Typical settings
%   s.sigmadog = 1.2;
%   s.xypadding = 5;
%   s.localization = 'DoG'; or 'intensity'
%   s.maxNpoints = 10000;
%
% To get default settings, use
% s = dotCandidates('getDefaults')
%
% Outputs:
%  x,y,z,dog,intensity
%
% Reminder:
%   3D DoG, not per plane
%
% See also:
%  df_fwhm, dotFitting, (A_settings, A_cells)
%
%

% grep --include=*.m -rnw '/home/erikw/code/dotter_matlab/' -e "dotCandidates"

if nargin == 0
    help dotCandidates
    return
end

returnDefaults = 0;
defaultsChannel = 'unknown';
voxelSize = [];

for kk = 1:numel(varargin)
    if strcmp(upper(varargin{kk}), 'GETDEFAULTS')
        returnDefaults = 1;
    end
    if strcmp(upper(varargin{kk}), 'CHANNEL')
        defaultsChannel = varargin{kk+1};
    end
    % Used to set the defaults
    if strcmp(upper(varargin{kk}), 'VOXELSIZE')
        voxelSize = varargin{kk+1};
    end
    if strcmp(upper(varargin{kk}), 'IMAGE')
        I = varargin{kk+1};
    end
    if strcmp(upper(varargin{kk}), 'SETTINGS')
        s = varargin{kk+1};
    end
    if strcmp(upper(varargin{kk}), 'LAMBDA')
        s.lambda = varargin{kk+1};
    end       
end


if nargin == 2
    if isnumeric(varargin{1})
        warning('Legacy mode')
        I = varargin{1};
        s = varargin{2};
    end
end

if nargin == 1
    if isnumeric(varargin{1})
        warning('Legacy mode')
        I = varargin{1};
        s = dotCandidates('getDefaults');
    end
end


if returnDefaults
    if ~exist('s', 'var')
        s = struct();
    end
    
    if numel(voxelSize) == 0
        voxelSize = df_getVoxelSize();
    end
    if ~isfield(s, 'lambda')
        s.lambda = df_getEmission(defaultsChannel);
    end
        
    % for a594 lambda = 617 nm pixel size, [130,130,300]
    % s.sigmadog = [1.2, 1.2, 1.7];
    s.sigmadog = [1.2*s.lambda/617*voxelSize(1)/130*[1,1], ...
                  1.7*s.lambda/617*voxelSize(3)/300];
    
    s.xypadding = 5;
    s.localizationMethods = {'DoG', 'intensity', 'gaussian'};
    s.rankingMethods = {'DoG', 'intensity', 'gaussian'};
    s.localization = 'DoG';
    s.ranking = 'gaussian';
    s.refinementMethods = {'none', 'Weighted Centre of Mass'};
    s.refinement = 'none';
    s.maxNpoints = 100000;
    s.useLP = 0;
    s.LPsigma = 1;
    s.dogDimension = 2;
    s.channel = defaultsChannel;
    s.calcFWHM = 0;
    
    P = s;        
    return
end

if ~isfield(s, 'useLP')
    s.useLP = 0;
end

s.verbose = 0;

nSat = verify_image(I); % Spot saturated pixels etc

I = double(I);

%% Step 1: localization
if s.verbose
    disp('Finding local maximas')
end

if strcmp(s.localization, 'DoG')
    disp('DoG localization')
    % DOG - Difference of Gaussians, i.e., approximation of Laplacian
    J = gsmooth(I, s.sigmadog, 'normalized')-gsmooth(I, s.sigmadog+0.01, 'normalized');
end

if strcmp(s.localization, 'intensity')
    disp('Intensity localization')
    J = I;
end

if strcmp(s.localization, 'gaussian')
    disp('Gaussian correlation localization')
    J = gcorr(I, s.sigmadog);
end

% D: Dilation of J, to find the local maximas
if size(I,3)>1
    
    sel = ones(3,3,3);           
    for z = [1,3] % Corners in z = 1,3 removed
        sel(1,1,z) = 0;
        sel(1,3,z) = 0;
        sel(3,1,z) = 0;
        sel(3,3,z) = 0;
    end    
    sel(2,2,2)=0; % Hole in the middle
    
    % Or 'plus?'
    sel = zeros(3,3,3);
    sel(:,2,2)=1;
    sel(2,:,2)=1;
    sel(2,2,:)=1;
    sel(2,2,2)=0; % Hole in the middle
    
    D = imdilate(J, strel('arbitrary', sel));
else
    disp('2D')
    sel = ones(3,3);
    sel(2,2)=0;
    D = imdilate(J, strel('arbitrary', sel));
end

J = clearBoarders(J, 3, -inf); % 3 was working fine
%K = clearBoarders(A, 1, -1);
%K=clearBoardersXY(A,s.xypadding,-1);

%% Ask before doing this!
nsat = sum(I(:)==2^16-1);
removeSaturated = 1;

if nsat>0
    qans = questdlg('There are saturated pixels in the image. Do you want to use them for dot detection?', 'Saturated pixels', 'No', 'Yes', 'No');
    switch qans
        case 'Yes'
            removeSaturated = 0;
        case 'No'
            removeSaturated = 1;
    end    
end

if removeSaturated
    J(I==2^16-1)=-1; % Don't consider saturated pixels
end


Pos = find(J>D);
[PX, PY, PZ]=ind2sub(size(I), Pos);

%%  Step 2: Ordering
if strcmp(s.ranking, 'DoG')
    disp('Ranking based on DoG')
    if s.dogDimension == 2
        for kk = 1:size(I,3)
            V(:,:,kk) = gsmooth(I(:,:,kk), s.sigmadog, 'normalized')-gsmooth(I(:,:,kk), s.sigmadog+0.01, 'normalized');
        end
    end
    
    if s.dogDimension == 3
        V = gsmooth(I, s.sigmadog, 'normalized')-gsmooth(I, s.sigmadog+0.01, 'normalized');
    end
end

if strcmp(s.ranking, 'intensity');
    disp('Ranking based on intensity')
    % Intensity - median
    V = I;
end

if strcmp(s.ranking,'gaussian')
    disp('Ranking based on gaussian correlation')
    % Gaussian correlation
    V = gcorr(I, s.sigmadog);
end



%% Refinement should go here

if strcmpi(s.refinement, 'none')
    disp('No refinement');
end

if strcmpi(s.refinement, 'Weighted Centre of Mass')
    disp('>> Refining using df_com3 with weighting')    
    X = df_com3(V, [PX, PY, PZ]', 1)';
    PX = X(:,1);
    PY = X(:,2);
    PZ = X(:,3);
end

%% Step 3: build the output

P(:,1)=PX; P(:,2)=PY; P(:,3)=PZ;
P(:,4)=V(Pos); % filter values
P(:,5)=I(Pos); % pixel values



% sort by the V-value
[~, IDX]=sort(P(:,4), 'descend');
P = P(IDX, :);

% seems like not a good idea
%P(:,4) = P(:,4)./P(:,5).^(1/2);

%% FWHM
if s.calcFWHM
    if isfield(s, 'nFWHM')
        nfwhm = s.nFWHM;
    else
        nfwhm = 500;
    end
    P = [P, -2*ones(size(P,1),1)];
    
    fprintf('fwhm for %d strongest dots...', nfwhm);
    nfwhm = min(nfwhm, size(P,1));
    f = df_fwhm(V, P(1:min(nfwhm,size(P,1)),1:3));
    P(1:nfwhm,6) = f(:,1);
    meta = {'x', 'y', 'z', 'fvalue', 'pixel', 'fwhm'};
    disp('        done');
else
    meta = {'x', 'y', 'z', 'fvalue', 'pixel'};
end

% Restrict the number of points used
if s.maxNpoints > 0
    if size(P,1)>s.maxNpoints
        P = P(1:s.maxNpoints, :);
    end
end

end

function nSat = verify_image(I)
% Warn about saturation
% Only known about 8- and 16- bit images.

if max(I(:))>256
    % 16 bit
    nSat = sum(I(:)==2^16-1);
    type = 16;
    if nSat>0
        fprintf(2, 'Warning: if the image is 16 bit there are %d saturated pixels\n', nSat);
    end
else
    nSat = sum(I(:)==2^8-1);
    type = 8;
    if nSat>0
        fprintf(2, 'Warning: if the image is 8 bit there are %d saturated pixels\n', nSat);
    end
end


if nSat>0
    fprintf(' Consider removing dots where the intensity is %d by:\n', 2^type-1);
    fprintf(' P = P(P(:,5)<%d,:)\n', 2^type-1);
end

end