function [ P, meta ] = df_getDots(varargin)
%df_getDots(varargin)
%
% Locates local maxias in I according to the settings in s
% s.maxNpoints maximum number of points to be returned, 0 - no limit
%
% To get default settings, use
% s = df_getDots('getDefaults')
%
% To get dots, use:
% D = df_getDots('Image', I, 'Settings', s);
%
% Outputs columns:
%  x,y,z,value,intensity
%   where x,y,z are the integer coordinates of the dots, value is the value
%   from the ranking method and intensity is I(x,y,z).
%
% Reminder:
%   3D DoG, not per plane
%
% See also:
%  df_fwhm, df_createNM_getDots
%
% This function replaces dot_candidates.m

% grep --include=*.m -rnw '/home/erikw/code/dotter_matlab/' -e "df_getDots"

if nargin == 0
    help df_getDots
    return
end

%keyboard % No voxel size supplied?

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
        s.voxelSize = varargin{kk+1};
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
        s = df_getDots('getDefaults');
    end
end

if returnDefaults
    if ~exist('s', 'var')
        s = struct();
    end
    
    if ~isfield(s, 'voxelsize')
        s.voxelSize = df_getVoxelSize();
    end
    
    if numel(s.voxelSize) == 0
       s.voxelSize = df_getVoxelSize();
    end
    
    if ~isfield(s, 'lambda')
        s.lambda = df_getEmission(defaultsChannel);
    end
                
    s.xypadding = 5;
    s.localizationMethods = {'DoG_XY+Z','gaussian', 'DoG_3D','DoG_2D', 'intensity'};
    s.localization = 'DoG_XY+Z';
    s.ranking = 'gaussian';
    s.refinementMethods = {'none', 'Weighted Centre of Mass'};
    s.refinement = 'none';
    s.maxNpoints = 100000;
    s.useLP = 0;
    s.LPsigma = 1;
    s.dogDimension = 2;
    s.channel = defaultsChannel;
    s.calcFWHM = 0;
    s.dotFWHM = df_fwhm_from_lambda(s.lambda);
    
    P = s;
    return
end

if ~isfield(s, 'useLP')
    s.useLP = 0;
end

s.verbose = 0;

% Spot saturated pixels etc
verify_image(I); 

I = double(I);


%% Basic Localization
% Kind of least squares

if s.verbose
    disp('Finding local maximas')
end
s.verbose = 1;
fprintf('FWHM for dot: %f %f %f\n', s.dotFWHM(1), s.dotFWHM(2), s.dotFWHM(3));
sigma = s.dotFWHM./s.voxelSize/2.35;
fprintf('sigma for dot: %f %f %f\n', sigma(1), sigma(2), sigma(3));
sigmadog = 1.72*sigma;
fprintf('Sigma for DoG: %f %f %f\n', sigmadog(1), sigmadog(2), sigmadog(3));

if s.verbose
        disp(s.localization)
end


if strcmpi(s.localization, 'DoG_2D')    
    % DOG - Difference of Gaussians, i.e., approximation of Laplacian        
    J = dog2(I, sigmadog);        
end

if strcmpi(s.localization, 'DoG_3D')
    % DOG - Difference of Gaussians, i.e., approximation of Laplacian        
    J = dog3(I, sigmadog);        
end

if strcmpi(s.localization, 'DoG_XY+Z')    
    % DOG - Difference of Gaussians, i.e., approximation of Laplacian        
    %J = dog3(I, sigmadog);    
    DXY = dog2(I, sigmadog);
    DZ = dogz(I, sigmadog);
    
    % TODO: balance these correct
    % 20190502, change coefficient on DZ from 1 to .5
    J = DXY+.5*DZ; 
    
end

if strcmpi(s.localization, 'intensity')
    if s.verbose
    disp('Intensity localization')
    end
    J = I;
end

if strcmpi(s.localization, 'gaussian')
    if s.verbose
    disp('Gaussian correlation localization')
    end
    
    J = gcorr(I, sigma);
end

if ~exist('J', 'var')
    error('The localization method was not recognized')
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
    if s.verbose
    disp('2D')
    end
    sel = ones(3,3);
    sel(2,2)=0;
    D = imdilate(J, strel('arbitrary', sel));
end

J = clearBoarders(J, 3, -inf); % 3 was working fine
%K = clearBoarders(A, 1, -1);
%K=clearBoardersXY(A,s.xypadding,-1);

% Detect and possibly remove pixels in J where I is saturated
J = removeSaturatedPixels(I,J); 

Pos = find(J>D);
[PX, PY, PZ]=ind2sub(size(I), Pos);

%% Refinement should go here

if strcmpi(s.refinement, 'none')
    if s.verbose
        disp('No refinement');
    end
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
P(:,4)=D(Pos); % filter values
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
    f = df_fwhm(I, P(1:min(nfwhm,size(P,1)),1:3));
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

return; 
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

function V = dogz(I, sigma)
sigma = [0,0,1].*sigma;
    V = gsmooth(I, sigma, 'normalized')-gsmooth(I, sigma+0.001, 'normalized');    
end

function V = dog2(I, sigma)
% Difference of gaussians, per 2D plane
for kk = 1:size(I,3)
    V(:,:,kk) = gsmooth(I(:,:,kk), sigma, 'normalized')-gsmooth(I(:,:,kk), sigma+0.001, 'normalized');
end
end

function V = dog3(I, sigma)
% Difference of gaussians, 3D
V = gsmooth(I, sigma, 'normalized')-gsmooth(I, sigma+0.001, 'normalized');
end


function J = removeSaturatedPixels(I,J)
%% Looks for saturated pixels and can remove them from the analysis if wanted.
% Most of all it is important to warn about this 

nsat = sum(I(:)==2^16-1);
removeSaturated = 0;

if 0
if nsat>0
    qans = questdlg('There are saturated pixels in the image. Do you want to use them for dot detection?', ...
        'Saturated pixels', 'No', 'Yes', 'No');
    switch qans
        case 'Yes'
            removeSaturated = 0;
        case 'No'
            removeSaturated = 1;
    end
end
end

if removeSaturated
    J(I==2^16-1)=-1; % Don't consider saturated pixels
end

end