function [nuclei, mask3, s]= get_nuclei_dapi_3(V, s, varargin)
% Find the nuclei in the dapi stack I
disp('Looking for cells ...')

minVolume = 100; % don't accept nuclei with less than this number of pixels

if(numel(size(V))~=3)
    warning('Image has to be 3D');
    nuclei = [];  mask3 = []; s = [];
    return
end

% Use watersheds for cell separation, might not be useful for deconvolved
% images
if nargin<2
    s.useWatershed = 1;
    s.preFilter = 1;
    s.minarea = 500;
end

if ~isfield(s, 'minarea')
    s.minarea = 500;
end

if ~isfield(s, 'preFilter')
    s.preFilter =1;
end

if ~isfield(s, 'useHP')
    s.useHP = 0;
end

if ~isfield(s, 'hpSigma')
    s.hpSigma = 1;
end

if ~isfield(s, 'excludeOnEdge')
    s.excludeOnEdge = 1;
end

if ~isfield(s, 'thresholding')
    s.thresholding = 1;
    s.mrfGC = 0;
end

if ~isfield(s, 'level')
    s.level = graythresh(V/max(V(:)));
end

if s.useHP
    fprintf('Smoothing ... ')
    tic
    V = gsmooth(V, s.hpSigma, 'normalized');
    t=toc;
    fprintf('%.1f s\n', toc);
end

mask3 = V>s.level*max(V(:));

if s.mrfGC
    V = V-min(V(:));
    V = V./max(V(:))*256;
    J = mrfGC(uint8(V), [s.mrfMean1, s.mrfStd1], [s.mrfMean2, s.mrfStd2], s.mrfSigma);
    mask3 = logical(J);
    s.level = 0;
end

%figure, imagesc(mask)

if(0)
    tic
    mask3 = imfill(mask3, 'holes');
    t = toc;
    fprintf('Holes filled in %.1f s\n', t);
else
    warning('Hole filling disabled')
end
% Filter out small things (not nuclei)
%mask = bwpropfilt(mask, 'Area', [s.minarea, inf]);

% Two methods for nuclei segmentataion, either the direct one
% or using watersheds to separate cells a little more.

if s.useWatershed
    fprintf('Watershed ... ');
    tic
    emask = imerode(mask3, strel('disk', 20));
    D = bwdist(emask, 'euclidean');
    D(~mask3)=Inf;
    L = double(watershed(D));
    L = L.*mask3;
    mask3 = L>0;
    t = toc;
    fprintf(' %.1f s\n', t);
end

if s.excludeOnEdge
    % Exclude cells connected to the boundary
    mask3(:,1,:)=1; mask3(:,end,:)=1;
    mask3(1,:,:)=1; mask3(end,:,:)=1;
    mask3(:,:,1)=0; mask3(:,:,end)=0; % skip the first and last slice
    [L, n] = bwlabeln(mask3);
    L(L==L(1,1,2))=0; % every
else
    [L, n] = bwlabeln(mask3);
end

N = [];
nucNum = 0;
fprintf('Processing %d nuclei candidates ...', n);
tic

assert(max(L(:)<2^16));
L = uint16(L);
H = histo16(L);
for kk=1:n
    clear nuclei
    if(H(kk+1) >= minVolume)
        % Bounding box, grow a little around the segmentation
        seg = L == kk;
        
        nucNum = nucNum +1;
        nuclei.bbx = bbox(seg);
        nuclei.bbx(1)=max(1, nuclei.bbx(1)-5);
        nuclei.bbx(2)=min(size(seg,1), nuclei.bbx(2)+5);
        nuclei.bbx(3)=max(1, nuclei.bbx(3)-5);
        nuclei.bbx(4)=min(size(seg,2), nuclei.bbx(4)+5);
        nuclei.centroid = [mean(nuclei.bbx(1:2)), mean(nuclei.bbx(3:4))];
        
        %nuclei.dapisum = sum(sum(seg.*V));
        nuclei.volume = sum(sum(seg));
        
        N{nucNum} = nuclei;
    end
end

% use a lookup-table to quickly set to 0 the tiny objects
LUT = uint16(0:2^16-1);
LUT(H<minVolume) = 0;
mask3 = intlut(L, LUT);

nuclei = N;
t = toc;
fprintf(' %.1ff s\n', t);
fprintf('Found %d nuclei\n', numel(N));

assert(numel(size(mask3))==3)
end
