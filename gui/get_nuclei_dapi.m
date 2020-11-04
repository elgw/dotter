function [nuclei, mask, s]= get_nuclei_dapi(I, s, varargin)
% Find the nuclei in the dapi stack I
disp('Looking for cells ...')

I = double(I);

if nargin<1 || nargin>2
    warning('Wrong number of inputs');
    return
end

if nargin==1
    warning('No settings provided, using dummy values');
    s.useWatershed = 1;
    s.preFilter = 1;
    s.minarea = 500;
    s.maxarea = inf;
end

if ~isfield(s, 'minarea')
    s.minarea = 500;
    s.maxarea = inf;
end

if ~isfield(s, 'preFilter')
    s.preFilter =1;
end

if ~isfield(s, 'useLP')
    s.useLP = 0;
end

if ~isfield(s, 'useDS')
    s.useDS = 0;
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

if s.useDS        
    I = -imclose(-I, strel('disk', s.DS_size));
end

if s.useLP    
    I = gsmooth(I, s.hpSigma, 'normalized');
end

if ~isfield(s, 'level')
    s.level = graythresh(I/max(I(:)));
end

mask = I/max(I(:))>s.level;

if s.mrfGC
    I = I-min(I(:));
    I = I./max(I(:))*256;
    J = mrfGC(uint8(I), [s.mrfMean1, s.mrfStd1], [s.mrfMean2, s.mrfStd2], s.mrfSigma);
    mask = logical(J);
    s.level = 0;
end

%figure, imagesc(mask)

mask = imfill(mask, 'holes');

% Filter out small things (not nuclei)

mask = bwpropfilt(mask, 'Area', [s.minarea, s.maxarea]);

% Two methods for nuclei segmentataion, either the direct one
% or using watersheds to separate cells a little more.

if s.useWatershed
    mask = ws_mask(mask, s);    
end

if s.excludeOnEdge
    % Exclude cells connected to the boundary
    mask(:,1)=1; mask(:,end)=1; mask(1,:)=1; mask(end,:)=1;
    [L, ~] = bwlabeln(mask);
    mask(L==L(1,1))=0;
    mask = bwpropfilt(mask, 'Area', [s.minarea, inf]);
end
[L, n] = bwlabeln(mask);


N = [];
for kk=1:n
    clear nuclei
    
    % Bounding box, grow a little around the segmentation
    seg = L == kk;
    nuclei.bbx = bbox(seg);
    nuclei.bbx(1)=max(1, nuclei.bbx(1)-5);
    nuclei.bbx(2)=min(size(seg,1), nuclei.bbx(2)+5);
    nuclei.bbx(3)=max(1, nuclei.bbx(3)-5);
    nuclei.bbx(4)=min(size(seg,2), nuclei.bbx(4)+5);
    nuclei.centroid = [mean(nuclei.bbx(1:2)), mean(nuclei.bbx(3:4))];
    
    nuclei.dapisum = sum(sum(seg.*I));
    nuclei.area = sum(sum(seg));
    
    N{kk} = nuclei;
end
mask = L;
nuclei = N;
disp('done looking for cells')
end

function wsmask = ws_mask(mask, s)    
    
    th = round(sqrt(s.maxarea/pi) / 6); % radius/6    
    th = max(th, 1);
    th = min(th, numel(mask)/6);
    %D = -bwdist(~(LL~=0));
    D = -bwdist(~mask);
    
    D = imclose(D, strel('disk', th));
    %D(D<-th) = -th;
    D(D==0) = Inf;
    W = watershed(D);
    wsmask = double(W).*double(mask>0);
    wsmask = wsmask>0; % Logical return value
    
end